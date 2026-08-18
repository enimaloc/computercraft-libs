-- Premier argument optionnel : ligne de depart sur le terminal natif, pour
-- partager l'ecran avec un autre programme qui occupe le haut (ex: "4" si
-- les lignes 1-3 sont deja utilisees). Absent -> tout l'ecran, comme avant.
local args = {...}
local startRow = 1
if tonumber(args[1]) then
    startRow = tonumber(table.remove(args, 1))
end
local channels = args

-- Le programme vit dans /twitch/ (voir install.lua) et peut etre lance
-- depuis n'importe quel repertoire courant : on ajoute son propre
-- repertoire a package.path pour que les require() ci-dessous resolvent
-- toujours vers leurs fichiers voisins.
-- Les entrees non-absolues de package.path sont recombinees par CC avec
-- le repertoire courant du shell (pwd) : sans le "/" en tete, on obtenait
-- pwd/twitch/color_utils.lua au lieu de /twitch/color_utils.lua.
local programDir = fs.getDir(shell.getRunningProgram())
if programDir:sub(1, 1) ~= "/" then
    programDir = "/" .. programDir
end
-- /lib/bootstrap.lua vit a un emplacement absolu fixe, independant de la
-- profondeur de ce programme (voir lib/bootstrap.lua) ; absent si les libs
-- n'ont pas encore ete installees, donc on ne l'appelle que s'il existe.
if fs.exists("/lib/bootstrap.lua") then
    dofile("/lib/bootstrap.lua")(programDir)
else
    package.path = programDir .. "/?.lua;" .. package.path
end

local Twitch = require("twitch_api")
local log = require("print_utils")
local colorUtils = require("color_utils")
local textUtils = require("text_utils")
local loader = require("override_loader")
local bot = Twitch.new(channels)

local engine = require("animation_engine")
local animate = require("animation_definition")
animate(engine)
loader.load(programDir)

-- Repere de depart sur l'ecran natif : si startRow > 1, chat et logs se
-- confinent tous les deux a une fenetre commencant a cette ligne au lieu
-- de tout l'ecran (le haut restant a un autre programme).
local nativeTarget = term.native()
if startRow > 1 then
    local w, h = nativeTarget.getSize()
    nativeTarget = window.create(nativeTarget, 1, startRow, w, math.max(1, h - startRow + 1), true)
    log.setTarget(nativeTarget)
end

local usersColor = {}

--- "[channel] " si plus d'une chaine est configuree, sinon "" (rien a
--- desambiguer). parsedMsg.params[1] est le "#channel" IRC du message.
local function channelPrefix(parsedMsg)
    if #channels <= 1 then return "" end
    local chan = parsedMsg.params and parsedMsg.params[1]
    return "[" .. (chan and chan:gsub("^#", "") or "?") .. "] "
end

local function readBotFile()
    local lines = {}
    local file = fs.open(fs.combine(programDir, "knownBots.txt"), "r")
    if not file then
        log.error("knownBots.txt not found")
        return lines
    end
    while true do
        local line = file.readLine()
        if not line then break end
        table.insert(lines, line)
    end
    file.close()
    return lines
end

local knownBots = readBotFile()

local function knownAsBot(name)
    for _, line in ipairs(knownBots) do
        if line == name then
            return true
        end
    end
    return false
end

local lastEvents = {}

-- Dedoublonnage des events sub/raid (evite de rejouer une animation si le
-- meme message est redelivre). Borne pour ne pas grossir indefiniment sur
-- une session de plusieurs jours.
local alreadyPlayedEvent = {}
local alreadyPlayedOrder = {}
local ALREADY_PLAYED_LIMIT = 200

local function markPlayed(id)
    if alreadyPlayedEvent[id] then return end
    alreadyPlayedEvent[id] = true
    table.insert(alreadyPlayedOrder, id)
    if #alreadyPlayedOrder > ALREADY_PLAYED_LIMIT then
        alreadyPlayedEvent[table.remove(alreadyPlayedOrder, 1)] = nil
    end
end

-- Le chat vit dans une fenetre plein ecran ; les animations dans une petite
-- fenetre en haut a droite (~1/4 de l'ecran), superposee mais independante :
-- une animation ne met donc plus le chat en pause ni ne force un
-- rafraichissement plein ecran. Quand un moniteur est branche, les deux
-- fenetres basculent dessus ; les logs (print_utils) restent eux toujours
-- sur term.native().
local activeMonitorSide = nil
local chatWin = nil

local function findMonitorSide()
    for _, name in ipairs(peripheral.getNames()) do
        if peripheral.getType(name) == "monitor" then
            return name
        end
    end
    return nil
end

local function redrawFromHistory()
    chatWin.clear()
    chatWin.setCursorPos(1, 1)
    for _, e in ipairs(lastEvents) do
        os.queueEvent(table.unpack(e))
    end
end

local function applyDisplay(displayTarget)
    local w, h = displayTarget.getSize()
    chatWin = window.create(displayTarget, 1, 1, w, h, true)
    term.redirect(chatWin)

    local cornerW = math.floor(w / 2)
    local cornerH = math.floor(h / 2)
    local cornerWin = window.create(displayTarget, w - cornerW + 1, 1, cornerW, cornerH, true)
    engine.setTarget(cornerWin)

    redrawFromHistory()
end

local function useMonitor(side)
    activeMonitorSide = side
    applyDisplay(peripheral.wrap(side))
end

local function useNativeTerm()
    activeMonitorSide = nil
    applyDisplay(nativeTarget)
end

local startupMonitorSide = findMonitorSide()
if startupMonitorSide then
    useMonitor(startupMonitorSide)
else
    useNativeTerm()
end

local function listen()
    while true do
        local event, msg = os.pullEvent()
        if event:find("^twitch") ~= nil then
            table.insert(lastEvents, {event, msg})
            local _, screenHeight = term.getSize()
            if #lastEvents > (screenHeight * 2) then
                table.remove(lastEvents, 1)
            end
            if event ~= "twitch_raw" then
            log.info(event)
            log.info(msg)
            end
        end
        if event == "animation_end" then
            -- L'animation a pu dessiner par-dessus le chat dans son coin ;
            -- chatWin garde le contenu correct pour cette zone, on la
            -- reaffiche simplement (pas besoin de tout redessiner).
            chatWin.redraw()
        else
            loader.dispatch(event, msg)
            if msg and type(msg) == "table" and msg.tags and type(msg.tags) == "table" and msg.tags["color"] and msg.tags["color"] ~= "" then
                usersColor[msg.tags["display-name"]] = colorUtils.getClosestColor(msg.tags["color"]:gsub("^#", ""))
            end
            if event == "twitch_join" then
                if msg["prefix"] == ((bot.username).."!"..(bot.username).."@"..(bot.username)..".tmi.twitch.tv") then
                    log.info("Connected to Twitch chat")
                    term.setTextColor(colors.gray)
                    write("Connecter sur le chat de " .. msg["params"][1])
                    term.setTextColor(colors.white)
                else
                    log.debug("[+] "..msg["prefix"])
                end
            elseif event == "twitch_part" then
                log.debug("[-] "..msg["prefix"])
            elseif event == "twitch_chat" and not knownAsBot(msg.tags["display-name"]) then
                -- Un /me arrive encapsule en CTCP : "\1ACTION message\1".
                local actionText = msg["trailing"] and msg["trailing"]:match("^\1ACTION (.*)\1$")
                local displayName = textUtils.sanitize(msg.tags["display-name"])
                local trailing = textUtils.sanitize(actionText or msg["trailing"])
                local color = usersColor[msg.tags["display-name"]]
                if color == nil then color = colors.white end
                local bgColor = term.getBackgroundColor()
                if msg.tags["msg-id"] and msg.tags["msg-id"] == "highlighted-message" then
                    term.setBackgroundColor(colors.purple)
                end
                write(channelPrefix(msg))
                write("<")
                term.setTextColor(color)
                write(displayName)
                term.setTextColor(colors.white)
                write("> "..trailing)
                term.setBackgroundColor(bgColor)
                print()

                local bits = tonumber(msg.tags["bits"])
                if bits and bits > 0 then
                    engine.queue("cheer", 0.3, { displayName.." a envoye "..bits.." bits", trailing })
                end
            elseif event == "twitch_sub" or event == "twitch_resub" then
                if not alreadyPlayedEvent[msg.tags["id"]] then
                    engine.queue("sub", 0.3)
                    markPlayed(msg.tags["id"])
                end
                local displayName = textUtils.sanitize(msg.tags["display-name"])
                local color = usersColor[msg.tags["display-name"]]
                if color == nil then color = colors.white end
                write(channelPrefix(msg))
                term.setBackgroundColor(color)
                write(" ")
                term.setBackgroundColor(colors.gray)
                write(textUtils.sanitize(msg.tags["system-msg"]:gsub("\\s"," ")))
                term.setBackgroundColor(colors.black)
                print()
                if msg["trailing"] and msg["trailing"] ~= "" then
                    write("<")
                    term.setTextColor(color)
                    write(displayName)
                    term.setTextColor(colors.white)
                    print("> "..textUtils.sanitize(msg["trailing"]))
                end
            elseif event == "twitch_raid" then
                if not alreadyPlayedEvent[msg.tags["id"]] then
                    local raider = textUtils.sanitize(msg.tags["msg-param-displayName"] or msg.tags["msg-param-login"] or "???")
                    local viewers = msg.tags["msg-param-viewerCount"] or "?"
                    engine.queue("raid", 0.3, { channelPrefix(msg)..raider.." arrive avec "..viewers.." viewers !" })
                    markPlayed(msg.tags["id"])
                end
            elseif event == "twitch_clearmsg" then
                -- On retrouve le message dans l'historique rejouable
                -- (lastEvents) et on reconstruit l'affichage sans lui.
                local targetId = msg.tags["target-msg-id"]
                for i, e in ipairs(lastEvents) do
                    local pastEvent, pastMsg = e[1], e[2]
                    if pastEvent == "twitch_chat" and pastMsg.tags and pastMsg.tags["id"] == targetId then
                        table.remove(lastEvents, i)
                        redrawFromHistory()
                        break
                    end
                end
            elseif event == "peripheral" and not activeMonitorSide and peripheral.getType(msg) == "monitor" then
                log.info("Moniteur connecte, redirection de l'affichage")
                useMonitor(msg)
            elseif event == "peripheral_detach" and msg == activeMonitorSide then
                log.warn("Moniteur deconnecte, retour a l'ecran de l'ordinateur")
                useNativeTerm()
            elseif event ~= "twitch_raw" and event ~= "websocket_message" and event ~= "timer" and event ~= "animation_start" and event ~= "animation_end" and event ~= "animation_frame_draw_started" and event ~= "animation_frame_draw_end" then
                log.debug(event)
                log.debug(msg)
            end
        end
    end
end

parallel.waitForAny(function() bot:start() end, engine.run, listen)
