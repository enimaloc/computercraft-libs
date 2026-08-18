local debugInfo = debug.getinfo(2, "S")
local from_require = debugInfo and debugInfo.what == "Lua" and debugInfo.source == "@/rom/modules/main/cc/require.lua"

local modem = peripheral.find("modem")
local USE_REDNET = modem ~= nil
local IS_SERVER = false
local IS_MAIN_SERVER = false
local SERVER_ID = nil
local SERVER_LABEL = nil

-- Charger ou crÃÂ©er les paramÃÂ¨tres par dÃÂ©faut
settings.define("tps.force_server", {
    description = "Forcer cet ordinateur ÃÂ  ÃÂªtre serveur TPS",
    default = false,
    type = "boolean"
})
settings.define("tps.hostname", {
    description = "Nom d'hÃÂ´te personnalisÃÂ© pour le protocole TPS",
    default = tostring(os.computerID()),
    type = "string"
})
settings.define("tps.main_server_label", {
    description = "Label du serveur principal (par dÃÂ©faut: 'spawn')",
    default = "spawn",
    type = "string"
})
settings.define("log.level", {
    description = "Niveau de logging (0: TRACE; 1: DEBUG; 2: INFO; 3: WARN; 4: ERROR)",
    default = 2,
    type = "number"
})
settings.load()
IS_MAIN_SERVER = USE_REDNET and settings.get("tps.hostname") == settings.get("tps.main_server_label")

-- Initialisation de _G.tps
_G.tps = 20.0

-- Ouvre Rednet si un modem est prÃÂ©sent
if USE_REDNET then
    rednet.open(peripheral.getName(modem))
    rednet.unhost("tps")
end

local function debug(msg)
    if settings.get("log.level") > 1 then return end
    print(msg)
end

local function info(msg)
    if settings.get("log.level") > 2 then return end
    print(msg)
end

local function warn(msg)
    if settings.get("log.level") > 3 then return end
    print(msg)
end

local function receive(timeout)
    local rId, message, proto
    repeat rId, message, proto = rednet.receive("tps", timeout) until timeout ~= nil or proto == "tps"
    return rId, message, proto
end

local function receiveFrom(id, timeout)
    local rId, message, proto
    repeat rId, message, proto = rednet.receive("tps", timeout) until timeout ~= nil or (rId == id and proto == "tps")
    return rId, message, proto
end

local function ping(id)
    if not USE_REDNET then
        return false
    end
    debug(("Try pinging %d"):format(id))
    rednet.send(id, { command = "ping" }, "tps")
    local rId, _, proto = receiveFrom(id, 10)
    debug(("Got ping from %d"):format(id))
    return rId == id and proto == "tps"
end

local function getLabel(id)
    if not USE_REDNET then
        return nil
    end
    debug(("Getting label of %d"):format(id))
    rednet.send(id, { command = "label" }, "tps")
    local _, message, _ = receiveFrom(id, 10)
    debug(("Got label of %d: %s"):format(id, message.label))
    return message.label
end

local function getServer(hostname)
    if not USE_REDNET then
        return false, nil, nil
    end
    debug(("Searching for tps server%s"):format(hostname and " with hostname == "..hostname or ""))
    local hosts = { rednet.lookup("tps", hostname) }
    debug(("Got %d servers"):format(#hosts))
    for _, id in pairs(hosts) do
        debug(("Trying %d"):format(id))
        if ping(id) then
            return true, id, getLabel(id)
        end
    end
    return false, nil, nil
end

local function getMainServer()
    return getServer(settings.get("tps.main_server_label"))
end

local function host(ask_permission)
    if ask_permission == nil then
        ask_permission = not settings.get("tps.force_server")
    end

    if ask_permission then
        info("Asking if I can be the server")
        rednet.broadcast({ command = "ask-become-server", id = os.computerID() }, "tps")
        local rId, message, _ = receive(10)
        if rId and message and message.command and message.command == "reject" then
            warn("Receive a reject answer waiting to retry...")
            sleep(10)
            tryBecomeServer()
            return
        end
    end

    info("Becoming server")
    IS_SERVER = true
    SERVER_ID = os.computerID()
    SERVER_LABEL = settings.get("tps.hostname")
    rednet.host("tps", SERVER_LABEL)
end

local function tryBecomeServer()
    if not USE_REDNET or settings.get("tps.force_server") then
        return
    end

    if (SERVER_ID and SERVER_LABEL == settings.get("tps.main_server_label") and ping(SERVER_ID)) then
        return
    end
    local available, id, label = getMainServer()
    if available then
        if not from_require then
            info("Serveur principal (" .. label .. ") dÃÂ©tectÃÂ©, bascule vers ce serveur.")
        end
        SERVER_ID = id
        SERVER_LABEL = label
        IS_SERVER = false
        rednet.unhost("tps")
        return
    end

    if (SERVER_ID and SERVER_LABEL and ping(SERVER_ID)) or IS_SERVER then
        return
    end
    available, id, label = getServer()
    if available then
        if not from_require then
            info("Serveur (" .. label .. ") dÃÂ©tectÃÂ©, bascule vers ce serveur.")
        end
        SERVER_ID = id
        SERVER_LABEL = label
        IS_SERVER = false
        rednet.unhost("tps")
        return
    end
    host()
end

local function calculate()
    if USE_REDNET and not IS_SERVER and SERVER_ID then
        rednet.send(SERVER_ID, { command = "request" }, "tps")
        local _, message, _ = receiveFrom(SERVER_ID, 2)
        if message and message.command == "answer" and message.tps then
            _G.tps = message.tps
        else
            -- Timeout
            SERVER_ID = nil
            SERVER_LABEL = nil
        end
    else
        local game_time_start = os.epoch("utc")
        sleep(1)
        local game_time_end = os.epoch("utc")
        local utc_elapsed_seconds = (game_time_end - game_time_start) / 1000
        _G.tps = 20 / utc_elapsed_seconds
        if (IS_SERVER or settings.get("tps.force_server")) and USE_REDNET then
            rednet.broadcast({ command = "tps", tps = _G.tps }, "tps")
        end
    end
    return _G.tps
end

local function firstConnect()
    if settings.get("tps.force_server") then
        host()
        return
    end
    local mainAvailable, id, label = getMainServer()
    if mainAvailable then
        SERVER_ID = id
        SERVER_LABEL = label
        return
    end
end

local function run()
    while true do
        local senderId, message, protocol = receive()
        if message and message.command then
            if message.command == "ping" then
                rednet.send(senderId, { command = "answer" }, "tps")
            elseif message.command == "label" then
                rednet.send(senderId, { command = "answer", label = settings.get("tps.hostname") }, "tps")
            elseif message.command == "ask-become-server" then
                if message.id < os.computerID() or IS_MAIN_SERVER then
                    rednet.send(senderId, { command = "reject" })
                end
            elseif message.command == "request" then
                rednet.send(senderId, { command = "answer", tps = _G.tps }, "tps")
            elseif message.command == "tps" then
                _G.tps = message.tps
            end
        end
    end
end

local function watchdog()
    firstConnect()
    while true do
        tryBecomeServer()
        sleep(1)
    end
end

local tps_lib = {
    calculate = calculate,
    getServerID = function()
        return SERVER_ID
    end,
    getServerLabel = function()
        return SERVER_LABEL
    end,
    isServer = function()
        return IS_SERVER
    end,
    isMainServer = function()
        return IS_MAIN_SERVER
    end,
    watchdog = watchdog,
    run = run,
    calculate = calculate
}

if false and not from_require then
    local function displayTps()
        local _, y = term.getCursorPos()
        term.setCursorPos(1, 1)
        local color
        if _G.tps > 18 then
            color = colors.green
        elseif _G.tps >= 15 then
            color = colors.orange
        else
            color = colors.red
        end
        if term.isColor() then
            term.setTextColor(color)
        end
        if not SERVER_ID or SERVER_ID == os.computerID() then
            ntfy.send("createmixam_tps", SERVER_LABEL, tostring(_G.tps))
            if _G.tps <= 18 then
                ntfy.send("createmixam_tps_warn", SERVER_LABEL, tostring(_G.tps))
                if _G.tps <= 16 then
                    ntfy.send("createmixam_tps_alert", SERVER_LABEL, tostring(_G.tps))
                end
            end
        end
        term.write(string.format("[%s] TPS: %.2f",
                SERVER_ID and SERVER_ID ~= os.computerID() and (SERVER_LABEL or SERVER_ID) or "local",
                _G.tps
        ))
        term.setTextColor(colors.white)
        term.setCursorPos(1, y)
    end

	local time = 5
	local function sendToNtfy()
		time = time - 1
		if (not SERVER_ID or SERVER_ID == os.computerID()) and (time <= 0 or _G.tps <= 18) then
            ntfy.send("createmixam_tps", SERVER_LABEL, tostring(_G.tps))
            if _G.tps <= 18 then
                ntfy.send("createmixam_tps_warn", SERVER_LABEL, tostring(_G.tps))
                if _G.tps <= 16 then
                    ntfy.send("createmixam_tps_alert", SERVER_LABEL, tostring(_G.tps))
                end
            end
			time = 5
        end
	end

    parallel.waitForAll(
            watchdog,
            run,
            function()
		        term.clear()
		        term.setCursorPos(1, 2)
                while true do
                    calculate()
                    displayTps()
					sendToNtfy()
                    sleep(1)
                end
            end
    )
else
    return tps_lib
end
