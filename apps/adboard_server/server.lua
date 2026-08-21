-- server.lua
-- Serveur adboard : recoit des visuels via rednet ("submit"), les stocke
-- sur disque sous /adboard-data/<w>x<h>/<id>.nfp, et pousse l'image
-- courante a chaque afficheur enregistre ("register" / "show"). Voir
-- docs/superpowers/specs/2026-08-21-adboard-design.md.

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

local DATA_DIR = "/adboard-data"
local HEARTBEAT_TIMEOUT = 90
local PRUNE_INTERVAL = 30
local PUSH_INTERVAL = 10

local modem = peripheral.find("modem")
if not modem then
    printError("[adboard-server] aucun modem attache, arret.")
    return
end
rednet.open(peripheral.getName(modem))
rednet.host(protocol.PROTOCOL, os.computerLabel() or ("adboard-server-" .. os.getComputerID()))

--- buckets["<w>x<h>"] = { { id = "...", path = "..." }, ... }
local buckets = {}

local submissionCounter = 0
local function generateId()
    submissionCounter = submissionCounter + 1
    return tostring(os.epoch("utc")) .. "-" .. tostring(submissionCounter)
end

local function bucketKey(width, height)
    return width .. "x" .. height
end

local function countImages()
    local total = 0
    for _, list in pairs(buckets) do
        total = total + #list
    end
    return total
end

--- Scanne DATA_DIR au demarrage et reconstruit l'index en memoire. Un
--- dossier/fichier illisible est ignore avec un avertissement -- non
--- bloquant pour le demarrage.
local function scanBuckets()
    buckets = {}
    if not fs.exists(DATA_DIR) then
        return
    end
    for _, sizeDir in ipairs(fs.list(DATA_DIR)) do
        local sizePath = fs.combine(DATA_DIR, sizeDir)
        if fs.isDir(sizePath) then
            local list = {}
            for _, fileName in ipairs(fs.list(sizePath)) do
                if fileName:match("%.nfp$") then
                    local id = fileName:gsub("%.nfp$", "")
                    table.insert(list, { id = id, path = fs.combine(sizePath, fileName) })
                else
                    print("[adboard-server] ignore (pas un .nfp) : " .. fileName)
                end
            end
            if #list > 0 then
                buckets[sizeDir] = list
            end
        end
    end
end

local function storeSubmission(width, height, nfp)
    local key = bucketKey(width, height)
    local dir = fs.combine(DATA_DIR, key)
    if not fs.exists(dir) then
        fs.makeDir(dir)
    end
    local id = generateId()
    local path = fs.combine(dir, id .. ".nfp")
    local file, err = fs.open(path, "w")
    if not file then
        return nil, err or "impossible d'ouvrir le fichier en ecriture"
    end
    file.write(nfp)
    file.close()
    buckets[key] = buckets[key] or {}
    table.insert(buckets[key], { id = id, path = path })
    return id
end

--- displays[senderId] = { width, height, lastSeen, nextImageIndex }
local displays = {}

local function handleRegister(senderId, msg)
    displays[senderId] = displays[senderId] or { nextImageIndex = 0 }
    displays[senderId].width = msg.width
    displays[senderId].height = msg.height
    displays[senderId].lastSeen = os.clock()
    rednet.send(senderId, protocol.registerAckMessage(), protocol.PROTOCOL)
end

local function handleSubmit(senderId, msg)
    local id, err = storeSubmission(msg.width, msg.height, msg.nfp)
    if id then
        rednet.send(senderId, protocol.submitAckMessage(true, id), protocol.PROTOCOL)
    else
        rednet.send(senderId, protocol.submitAckMessage(false, nil, err), protocol.PROTOCOL)
    end
end

local function listen()
    while true do
        local senderId, msg = rednet.receive(protocol.PROTOCOL)
        if type(msg) == "table" then
            if msg.type == "register" then
                handleRegister(senderId, msg)
            elseif msg.type == "submit" then
                handleSubmit(senderId, msg)
            end
        end
    end
end

local function pruneDisplays()
    while true do
        os.sleep(PRUNE_INTERVAL)
        local now = os.clock()
        for senderId, display in pairs(displays) do
            if now - display.lastSeen > HEARTBEAT_TIMEOUT then
                displays[senderId] = nil
            end
        end
    end
end

local function pushLoop()
    while true do
        os.sleep(PUSH_INTERVAL)
        for senderId, display in pairs(displays) do
            local key = bucketKey(display.width, display.height)
            local bucket = buckets[key]
            if bucket and #bucket > 0 then
                display.nextImageIndex = (display.nextImageIndex % #bucket) + 1
                local entry = bucket[display.nextImageIndex]
                local file = fs.open(entry.path, "r")
                if file then
                    local nfp = file.readAll()
                    file.close()
                    rednet.send(senderId, protocol.showMessage(nfp), protocol.PROTOCOL)
                end
            end
        end
    end
end

scanBuckets()
print("[adboard-server] pret, " .. countImages() .. " visuel(s) charge(s).")
parallel.waitForAny(listen, pruneDisplays, pushLoop)
