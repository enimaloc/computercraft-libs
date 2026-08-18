-- override_loader.lua
-- Decouvre et charge les fichiers *.override.lua locaux au computer 0 :
-- du comportement custom qui survit aux syncs d'install.lua. Voir
-- docs/superpowers/specs/2026-08-17-override-loader-design.md.

local log = require("print_utils")

-- Capture avant toute redeclaration locale de "load" plus bas dans ce
-- fichier (le nom public du module est aussi "load").
local luaLoad = load

local hooks = {}

local function addHook(eventName, fn)
    if not hooks[eventName] then
        hooks[eventName] = {}
    end
    table.insert(hooks[eventName], fn)
end

--- Echappe les caracteres speciaux d'un pattern Lua, pour construire un
--- pattern sur un nom de commande arbitraire sans risquer une erreur ou un
--- faux-positif si ce nom contient un caractere magique.
local function escapePattern(s)
    return (s:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", "%%%1"))
end

--- Extrait le texte utile d'un message twitch_chat, en retirant
--- l'encapsulation CTCP d'un /me ("\1ACTION texte\1"), comme le fait deja
--- twitch.lua pour l'affichage.
local function chatText(msg)
    if not (msg and msg.trailing) then return nil end
    local actionText = msg.trailing:match("^\1ACTION (.*)\1$")
    return actionText or msg.trailing
end

local function buildApi()
    return {
        on = function(eventName, fn)
            addHook(eventName, fn)
        end,
        onCommand = function(name, fn)
            local pattern = "^!" .. escapePattern(name)
            addHook("twitch_chat", function(event, msg)
                local text = chatText(msg)
                if not text then return end
                local argsString = text:match(pattern .. "%s+(.*)$")
                if argsString then
                    fn(msg, argsString)
                elseif text:match(pattern .. "$") then
                    fn(msg, "")
                end
            end)
        end,
    }
end

local function readFile(path)
    local file = fs.open(path, "r")
    if not file then return nil end
    local content = file.readAll()
    file.close()
    return content
end

--- Charge un override par lecture + compilation directe du fichier
--- (fs.open + load), plutot que require() : le nom d'un override contient
--- toujours un point ("xxx.override"), que require() interprete comme un
--- separateur de chemin et cherche donc "xxx/override.lua" au lieu du
--- fichier reel.
local function load(programDir)
    for _, name in ipairs(fs.list(programDir)) do
        if name:match("%.override%.lua$") then
            local path = fs.combine(programDir, name)
            local content = readFile(path)
            if not content then
                log.error("override " .. name .. " (chargement) : fichier illisible")
            else
                -- L'env explicite est indispensable : par defaut load()
                -- utilise l'environnement global "brut" de la VM, pas celui
                -- du programme CraftOS en cours (qui expose require/fs/os).
                -- Sans lui, le chunk charge ne voit ni require ni les API CC.
                local chunk, loadErr = luaLoad(content, name, "t", _ENV)
                if not chunk then
                    log.error("override " .. name .. " (chargement) : " .. tostring(loadErr))
                else
                    local ok, moduleOrErr = pcall(chunk)
                    if not ok then
                        log.error("override " .. name .. " (chargement) : " .. tostring(moduleOrErr))
                    elseif type(moduleOrErr) ~= "function" then
                        log.error("override " .. name .. " doit retourner une fonction(api)")
                    else
                        local api = buildApi()
                        local callOk, callErr = pcall(moduleOrErr, api)
                        if not callOk then
                            log.error("override " .. name .. " (init) : " .. tostring(callErr))
                        end
                    end
                end
            end
        end
    end
end

local function dispatch(event, msg)
    local fns = hooks[event]
    if not fns then return end
    for _, fn in ipairs(fns) do
        local ok, err = pcall(fn, event, msg)
        if not ok then
            log.error("override handler (" .. event .. ") : " .. tostring(err))
        end
    end
end

return {
    load = load,
    dispatch = dispatch,
}
