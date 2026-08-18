local programDir = fs.getDir(shell.getRunningProgram())
if programDir:sub(1, 1) ~= "/" then
    programDir = "/" .. programDir
end
local bootstrapPath = fs.combine(programDir, "../lib/bootstrap.lua")
if fs.exists(bootstrapPath) then
    dofile(bootstrapPath)(programDir)
else
    package.path = programDir .. "/?.lua;" .. package.path
end

local TWITCH_HOST = "twitch.tv"

local tpsOk, tps = pcall(require, "tps")
if not tpsOk then printError("tps module not installed") end

local ntfyOk, ntfy = pcall(require, "ntfy")
if not ntfyOk then printError("ntfy module not installed") end

local chatOk, chat = pcall(require, "chat")
if not chatOk then printError("chat module not installed") end

local twitchOk, Twitch = pcall(require, "twitch_api")
if not twitchOk then printError("twitch_api module not installed") end

local threads = {}

--------------------------------------------------------------------------
-- TPS : calcul + affichage + alerte ntfy en dessous des seuils
--------------------------------------------------------------------------

if tpsOk then
    local function tpsColor()
        if _G.tps > 18 then return colors.green end
        if _G.tps >= 15 then return colors.orange end
        return colors.red
    end

    local function reportToNtfy()
        if not ntfyOk then return end
        if tps.getServerID() and tps.getServerID() ~= os.computerID() then
            return
        end
        ntfy.send("createmixam_tps", tps.getServerLabel(), tostring(_G.tps))
        if _G.tps <= 18 then
            ntfy.send("createmixam_tps_warn", tps.getServerLabel(), tostring(_G.tps))
            if _G.tps <= 16 then
                ntfy.send("createmixam_tps_alert", tps.getServerLabel(), tostring(_G.tps))
            end
        end
    end

    local function displayTps()
        if term.isColor() then
            term.setTextColor(tpsColor())
        end
        term.setCursorPos(1, 1)
        term.write(string.format("[%s] TPS: %.2f",
            tps.getServerID() and tps.getServerID() ~= os.computerID() and (tps.getServerLabel() or tps.getServerID()) or "local",
            _G.tps
        ))
        term.setTextColor(colors.white)
    end

    -- Rapport ntfy au plus toutes les 5s, sauf en dessous du seuil (18) ou
    -- il est envoye a chaque tick pour suivre l'alerte de pres.
    local nNtfyCountdown = 5
    local function tickNtfy()
        nNtfyCountdown = nNtfyCountdown - 1
        if nNtfyCountdown <= 0 or _G.tps <= 18 then
            reportToNtfy()
            nNtfyCountdown = 5
        end
    end

    table.insert(threads, tps.watchdog)
    table.insert(threads, tps.run)
    table.insert(threads, function()
        term.clear()
        term.setCursorPos(1, 2)
        while true do
            tps.calculate()
            displayTps()
            tickNtfy()
            sleep(1)
        end
    end)
end

--------------------------------------------------------------------------
-- Chat : relaie chaque chaine Twitch vers un salon rednet "<chaine>.twitch.tv".
-- Pas de liste de chaines figee : une chaine est rejointe a la demande, la
-- premiere fois qu'un client rednet local cherche a s'y connecter -- voir
-- router:onUnknownSubhost.
--------------------------------------------------------------------------

if chatOk and twitchOk then
    local bot = Twitch.new({})
    local router = chat.ChatRouter.new()
    local tChannelUsers = {}

    --- Fait rejoindre sChannel au bot Twitch et cree le salon rednet
    --- correspondant. Idempotent : bot:join() est un no-op si deja rejoint.
    local function joinChannel(sChannel)
        bot:join(sChannel)
        tChannelUsers["#" .. sChannel] = tChannelUsers["#" .. sChannel] or {}

        local chatChannel = chat.ChatHost.new(sChannel .. "." .. TWITCH_HOST, {
            commands = {
                ["users"] = function(tUser)
                    local sUsers = "*"
                    for _, sOtherUser in ipairs(tChannelUsers["#" .. sChannel]) do
                        sUsers = sUsers .. " " .. sOtherUser
                    end
                    chatChannel:send(sUsers, tUser.nUserID)
                end,
                ["me"] = function(tUser) end,
                ["nick"] = function(tUser) end
            },
            onLogin = function(tUser)
                chatChannel:send("Ce salon est en lecture seul", tUser.nUserID)
                return false, ""
            end,
            onLogout = function(tUser) return false, "" end
        })
        router:register(chatChannel)
        return chatChannel
    end

    router:onUnknownSubhost(TWITCH_HOST, function(sSubhost)
        return joinChannel(sSubhost)
    end)

    --- Retire sNick de la liste des utilisateurs de sTwitchChannel
    --- ("#chaine"). No-op si absent.
    local function removeUser(sTwitchChannel, sNick)
        local tUsers = tChannelUsers[sTwitchChannel]
        if not tUsers then return end
        for i, sExisting in ipairs(tUsers) do
            if sExisting == sNick then
                table.remove(tUsers, i)
                return
            end
        end
    end

    local function nickFromPrefix(msg)
        return require("cc.strings").split(msg.prefix, "!")[1]
    end

    local function listen()
        while true do
            local event, msg = os.pullEvent()
            if event == "twitch_join" then
                local sTwitchChannel = msg.params[1]
                tChannelUsers[sTwitchChannel] = tChannelUsers[sTwitchChannel] or {}
                table.insert(tChannelUsers[sTwitchChannel], nickFromPrefix(msg))

            elseif event == "twitch_part" then
                removeUser(msg.params[1], nickFromPrefix(msg))

            elseif event == "twitch_chat" then
                local sTwitchChannel = msg.params[1]
                local chatChannel = router.tRooms[sTwitchChannel:sub(2) .. "." .. TWITCH_HOST]
                if chatChannel then
                    chatChannel:sendAs(msg.tags["display-name"], msg.trailing)
                end
            end
        end
    end

    table.insert(threads, function() router:start() end)
    table.insert(threads, function() bot:start() end)
    table.insert(threads, listen)
end

parallel.waitForAll(table.unpack(threads))
