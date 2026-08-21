-- submit.lua
-- Client de soumission adboard : editeur pixel-art minimal cale sur la
-- resolution du monitor attache, envoie le resultat au serveur via
-- rednet. Voir docs/superpowers/specs/2026-08-21-adboard-design.md.

local args = {...}

local programDir = fs.getDir(shell.getRunningProgram())
if programDir:sub(1, 1) ~= "/" then
    programDir = "/" .. programDir
end
if fs.exists("/lib/bootstrap.lua") then
    local file = fs.open("/lib/bootstrap.lua", "r")
    local bootstrap = load(file.readAll(), "/lib/bootstrap.lua", "t", _ENV)
    file.close()
    bootstrap()(programDir)
else
    package.path = programDir .. "/?.lua;" .. package.path
end

local protocol = require("adboard_protocol")

local SERVER_ID_FILE = "/etc/adboard/server_id"

--- Sauvegarde l'id serveur passe en argument, ou relit celui deja
--- persiste. Meme pattern que la persistance de host dans ccbridge.
local function resolveServerId()
    if args[1] then
        local dir = fs.getDir(SERVER_ID_FILE)
        if not fs.exists(dir) then
            fs.makeDir(dir)
        end
        local file = fs.open(SERVER_ID_FILE, "w")
        file.write(tostring(args[1]))
        file.close()
        return tonumber(args[1])
    end
    if fs.exists(SERVER_ID_FILE) then
        local file = fs.open(SERVER_ID_FILE, "r")
        local content = file.readAll()
        file.close()
        return tonumber(content)
    end
    return nil
end

local serverId = resolveServerId()
if not serverId then
    printError("[adboard-submit] aucun id serveur configure. Usage : submit <id_serveur>")
    return
end

local modem = peripheral.find("modem")
if not modem then
    printError("[adboard-submit] aucun modem attache, arret.")
    return
end
rednet.open(peripheral.getName(modem))

local monitor = peripheral.find("monitor")
if not monitor then
    printError("[adboard-submit] aucun monitor attache, arret.")
    return
end

local width, height = monitor.getSize()

--- Mapping caractere -> couleur CC, identique au programme paint natif.
local PALETTE_KEYS = {
    ["1"] = colors.white, ["2"] = colors.orange, ["3"] = colors.magenta,
    ["4"] = colors.lightBlue, ["5"] = colors.yellow, ["6"] = colors.lime,
    ["7"] = colors.pink, ["8"] = colors.gray, ["9"] = colors.lightGray,
    a = colors.cyan, b = colors.purple, c = colors.blue,
    d = colors.brown, e = colors.green, f = colors.red, g = colors.black,
}

--- grid[y][x] = couleur CC ou nil (transparent)
local grid = {}
for y = 1, height do
    grid[y] = {}
end

local selectedColor = colors.white

local function paintCell(x, y)
    grid[y][x] = selectedColor
    monitor.setCursorPos(x, y)
    monitor.setBackgroundColor(selectedColor)
    monitor.write(" ")
end

local function submit()
    local nfp = protocol.encodeNfp(grid, width, height)
    rednet.send(serverId, protocol.submitMessage(width, height, nfp), protocol.PROTOCOL)
    local _, msg = rednet.receive(protocol.PROTOCOL, 5)
    if not msg then
        print("[adboard-submit] pas de reponse du serveur (timeout).")
        return
    end
    if msg.type == "submit_ack" then
        if msg.ok then
            print("[adboard-submit] envoye, id=" .. tostring(msg.id))
        else
            print("[adboard-submit] echec : " .. tostring(msg.error))
        end
    end
end

monitor.setBackgroundColor(colors.black)
monitor.clear()
print("Palette : 1-9, a-g. Touchez le monitor pour peindre.")
print("'s' pour envoyer, 'q' pour quitter.")

while true do
    local event, p1, p2, p3 = os.pullEvent()
    if event == "monitor_touch" then
        local x, y = p2, p3
        if grid[y] and x >= 1 and x <= width then
            paintCell(x, y)
        end
    elseif event == "char" then
        local char = p1
        if PALETTE_KEYS[char] then
            selectedColor = PALETTE_KEYS[char]
        elseif char == "s" then
            submit()
        elseif char == "q" then
            return
        end
    end
end
