-- display.lua
-- Client d'affichage adboard : s'enregistre aupres du serveur pour sa
-- resolution de monitor et affiche ce qu'il pousse ("show"). Voir
-- docs/superpowers/specs/2026-08-21-adboard-design.md.
--
-- N'utilise pas paintutils.drawImage/parseImage : ca demanderait de
-- rediriger term vers le monitor (term.redirect), ce qui rediriger aussi
-- les print() de statut de ce programme vers le monitor au lieu du
-- terminal du computer. drawNfp() ci-dessous reproduit le meme decodage
-- (digit hex -> 2 ^ valeur, espace -> transparent) directement sur le
-- monitor, sans toucher term.

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
local HEARTBEAT_INTERVAL = 30

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
    printError("[adboard-display] aucun id serveur configure. Usage : display <id_serveur>")
    return
end

local modem = peripheral.find("modem")
if not modem then
    printError("[adboard-display] aucun modem attache, arret.")
    return
end
rednet.open(peripheral.getName(modem))

local monitor = peripheral.find("monitor")
if not monitor then
    printError("[adboard-display] aucun monitor attache, arret.")
    return
end

local width, height = monitor.getSize()

--- Decodage identique a paintutils.parseImage : un digit hex par pixel
--- (2 ^ valeur), un espace = transparent (rien dessine, cellule laissee
--- telle quelle).
local function drawNfp(nfp)
    local y = 1
    for line in (nfp .. "\n"):gmatch("(.-)\n") do
        if y > height then break end
        for x = 1, math.min(#line, width) do
            local c = line:sub(x, x)
            if c ~= " " then
                local value = tonumber(c, 16)
                if value then
                    monitor.setCursorPos(x, y)
                    monitor.setBackgroundColor(2 ^ value)
                    monitor.write(" ")
                end
            end
        end
        y = y + 1
    end
end

local function register()
    rednet.send(serverId, protocol.registerMessage(width, height), protocol.PROTOCOL)
end

local function heartbeat()
    while true do
        register()
        os.sleep(HEARTBEAT_INTERVAL)
    end
end

local function listen()
    while true do
        local senderId, msg = rednet.receive(protocol.PROTOCOL)
        if senderId == serverId and type(msg) == "table" and msg.type == "show" then
            drawNfp(msg.nfp)
        end
    end
end

monitor.setBackgroundColor(colors.black)
monitor.clear()
register()
print("[adboard-display] enregistre aupres de " .. serverId .. ", en attente...")
parallel.waitForAny(heartbeat, listen)
