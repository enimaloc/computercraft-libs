local programDir = fs.getDir(shell.getRunningProgram())
if programDir:sub(1, 1) ~= "/" then
    programDir = "/" .. programDir
end
local bootstrapPath = fs.combine(programDir, "../../lib/bootstrap.lua")
if fs.exists(bootstrapPath) then
    dofile(bootstrapPath)(programDir)
else
    package.path = programDir .. "/?.lua;" .. package.path
end

local CHANNELS = {"jimmynovaaa", "hackthedoc"}

local tpsOk, tps = pcall(require, "tps")
if not tpsOk then printError("tps module not installed") end

local chatOk, chat = pcall(require, "chat")
if not chatOk then printError("chat module not installed") end

local threads = {}

if tpsOk then
    local ntfy = require("ntfy")
    local function displayTps()
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
        if not tps.getServerID() or tps.getServerID() == os.computerID() then
            ntfy.send("createmixam_tps", tps.getServerLabel(), tostring(_G.tps))
            if _G.tps <= 18 then
                ntfy.send("createmixam_tps_warn", tps.getServerLabel(), tostring(_G.tps))
                if _G.tps <= 16 then
                    ntfy.send("createmixam_tps_alert", tps.getServerLabel(), tostring(_G.tps))
                end
            end
        end
        term.setCursorPos(1,1)
        term.write(string.format("[%s] TPS: %.2f",
                tps.getServerID() and tps.getServerID() ~= os.computerID() and (tps.getServerLabel() or tps.getServerID()) or "local",
                _G.tps
        ))
        term.setTextColor(colors.white)
    end

	local time = 5
  	local function sendToNtfy()
		  time = time - 1
		  if (not tps.getServerID() or tps.getServerID() == os.computerID()) and (time <= 0 or _G.tps <= 18) then
      ntfy.send("createmixam_tps", tps.getServerLabel(), tostring(_G.tps))
        if _G.tps <= 18 then
          ntfy.send("createmixam_tps_warn", tps.getServerLabel(), tostring(_G.tps))
          if _G.tps <= 16 then
            ntfy.send("createmixam_tps_alert", tps.getServerLabel(), tostring(_G.tps))
          end
      end
			 time = 5
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
				               	sendToNtfy()
                    sleep(1)
                end
            end
    )
end

if chatOk then
  local twitchOk, twitch = pcall(require, "twitch_api")
  local twitchRouting = {}
  local twitchUsers = {}
  
  if twitchOk then
    local router = chat.ChatRouter.new()
    for _, channel in ipairs(CHANNELS) do
      local chatChannel = chat.ChatHost.new(channel..".twitch.tv", {
        commands = {
          ["users"] = function(tUser, sContent)
            self:send("* Connected Users:", tUser.nUserID)
            local sUsers = "*"
            for _, tOtherUser in pairs(twitchUsers["#"..channel]) do
              sUsers = sUsers .. " " .. tOtherUser
            end
            self:send(sUsers, tUser.nUserID)
          end
        }
      })
      twitchRouting["#"..channel] = chatChannel
      twitchUsers["#"..channel] = {}
      router:register(chatChannel)
    end
    
    local bot = twitch.new(CHANNELS)
    
    local function listen()
      while true do
        local event, msg = os.pullEvent()
        if event == "twitch_join" then
--          print(textutils.serialise(msg))
          table.insert(twitchUsers[msg.params[1]], require "cc.strings".split(msg.prefix, "!")[1])
        elseif event == "twitch_part" then
--          print(textutils.serialise(msg))
          table.remove(twitchUsers[msg.params[1]], require "cc.strings".split(msg.prefix, "!")[1])
        elseif event == "twitch_chat" then
--          print(textutils.serialise(msg))
          twitchRouting[msg.params[1]]:sendAs(msg.tags["display-name"], msg["trailing"])
        end
      end
    end
    
    table.insert(threads, function() router:start() end)
    table.insert(threads, function() bot:start() end)
    table.insert(threads, listen)
  end
end  

parallel.waitForAll(table.unpack(threads))
