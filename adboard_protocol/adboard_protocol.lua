-- adboard_protocol.lua
-- Format des messages rednet et encodage .nfp partages par server.lua,
-- submit.lua et display.lua. Voir
-- docs/superpowers/specs/2026-08-21-adboard-design.md pour le design complet.
local expect = require("cc.expect").expect

local PROTOCOL = "adboard"

local function submitMessage(width, height, nfp)
    expect(1, width, "number")
    expect(2, height, "number")
    expect(3, nfp, "string")
    return { type = "submit", width = width, height = height, nfp = nfp }
end

local function submitAckMessage(ok, id, error)
    expect(1, ok, "boolean")
    expect(2, id, "string", "nil")
    expect(3, error, "string", "nil")
    return { type = "submit_ack", ok = ok, id = id, error = error }
end

local function registerMessage(width, height)
    expect(1, width, "number")
    expect(2, height, "number")
    return { type = "register", width = width, height = height }
end

local function registerAckMessage()
    return { type = "register_ack" }
end

local function showMessage(nfp)
    expect(1, nfp, "string")
    return { type = "show", nfp = nfp }
end

--- grid[y][x] = couleur CC (ex. colors.red) ou nil (transparent). Renvoie
--- height lignes de width caracteres (un digit hex par pixel via
--- colors.toBlit, " " si transparent), jointes par "\n" -- l'inverse exact
--- de ce que paintutils.parseImage decode (digit hex -> 2 ^ valeur, espace
--- -> nil), donc directement consommable par paintutils cote afficheur.
local function encodeNfp(grid, width, height)
    expect(1, grid, "table")
    expect(2, width, "number")
    expect(3, height, "number")
    local lines = {}
    for y = 1, height do
        local row = grid[y]
        local chars = {}
        for x = 1, width do
            local colour = row and row[x]
            if colour then
                chars[x] = colors.toBlit(colour)
            else
                chars[x] = " "
            end
        end
        lines[y] = table.concat(chars)
    end
    return table.concat(lines, "\n")
end

return {
    PROTOCOL = PROTOCOL,
    submitMessage = submitMessage,
    submitAckMessage = submitAckMessage,
    registerMessage = registerMessage,
    registerAckMessage = registerAckMessage,
    showMessage = showMessage,
    encodeNfp = encodeNfp,
}
