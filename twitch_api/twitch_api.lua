-- twitch_api.lua
local log = require("print_utils")
local Twitch = {}
Twitch.__index = Twitch

local function debugLog(msg)
    if (log) then log.debug(msg)
    else print("[DEBUG] "..msg)
    end
end

local function infoLog(msg)
    if (log) then log.info(msg)
    else print("[INFO] "..msg)
    end
end

local function warnLog(msg)
    if (log) then log.warn(msg)
    else print("[WARN] "..msg)
    end
end

function Twitch.new(channels, proxy, username, token)
    return setmetatable({
        channels = channels,
        username = username or "justinfan12345",
        token = token or "oauth:kappa",
        proxy = proxy or "ws://ws.twitch.enimaloc.fr",
        ws = nil
    }, Twitch)
end

--- Connexion au WebSocket Twitch IRC. Reessaie indefiniment (au lieu de
--- planter tout le programme) tant que la connexion echoue.
function Twitch:connect()
    infoLog("Connexion a Twitch IRC...")
    while true do
        local ws, err = http.websocket(self.proxy.."/"..table.concat(self.channels, ","))
        if ws then
            self.ws = ws
            return
        end
        warnLog("Connexion WebSocket echouee ("..tostring(err).."), nouvelle tentative dans 5s")
        sleep(5)
    end

    --self.ws.send("PASS " .. self.token)
    --self.ws.send("NICK " .. self.username)
    --self.ws.send("JOIN #" .. self.channel)
    --self.ws.send("CAP REQ :twitch.tv/tags twitch.tv/commands twitch.tv/membership")
end

--- Parsing des tags IRC Twitch : @a=b;c=d
local function parseTags(raw)
    local tags = {}
    for key, value in raw:gmatch("([^=;]+)=([^;]*)") do
        tags[key] = value
    end
    return tags
end

--- Parsing complet des messages IRC Twitch
local function parseIRC(message)
    local tags, prefix, command, params, trailing

    if message:sub(1,1) == '@' then
        tags, message = message:match("@([^ ]+) (.+)")
        tags = parseTags(tags or "")
    else
        tags = {}
    end

    if message:sub(1,1) == ':' then
        prefix, message = message:match(":([^ ]+) (.+)")
    end

    command, params = message:match("([^ ]+) (.+)")
    if params then
        local trailingStart = params:find(" :")
        if trailingStart then
            trailing = params:sub(trailingStart + 2)
            params = params:sub(1, trailingStart - 1)
        end
    end

    local paramList = {}
    if params then
        for param in params:gmatch("[^ ]+") do
            table.insert(paramList, param)
        end
    end

    return {
        tags = tags,
        prefix = prefix,
        command = command,
        params = paramList,
        trailing = trailing
    }
end

--- Démarre la boucle d'écoute
function Twitch:start()
    self:connect()
    while true do
        local event, url, message = os.pullEventRaw()
        if event == "terminate" then
            if self.ws then self.ws.close() end
            break
        elseif event == "websocket_message" then
            for line in message:gmatch("[^\r\n]+") do
                if line:sub(1, 4) == "PING" then
                    self.ws.send("PONG :" .. line:sub(7))
                    os.queueEvent("twitch_ping")
                else
                    local parsed = parseIRC(line)
                    os.queueEvent("twitch_raw", parsed)

                    if parsed.command == "PRIVMSG" then
                        os.queueEvent("twitch_chat", parsed)
                    elseif parsed.command == "JOIN" then
                        os.queueEvent("twitch_join", parsed)
                    elseif parsed.command == "PART" then
                        os.queueEvent("twitch_part", parsed)
                    elseif parsed.command == "NOTICE" then
                        os.queueEvent("twitch_notice", parsed)
                    elseif parsed.command == "CLEARCHAT" then
                        os.queueEvent("twitch_clear", parsed)
                    elseif parsed.command == "CLEARMSG" then
                        os.queueEvent("twitch_clearmsg", parsed)
                    elseif parsed.command == "USERNOTICE" then
                        local subEvent = parsed.tags["msg-id"]
                        if subEvent == "sub" then
                            os.queueEvent("twitch_sub", parsed)
                        elseif subEvent == "resub" then
                            os.queueEvent("twitch_resub", parsed)
                        elseif subEvent == "subgift" then
                            os.queueEvent("twitch_subgift", parsed)
                        elseif subEvent == "announcement" then
                            os.queueEvent("twitch_announcement", parsed)
                        elseif subEvent == "submysterygift" then
                            os.queueEvent("twitch_anonymous_subgift", parsed)
                        elseif subEvent == "raid" then
                            os.queueEvent("twitch_raid", parsed)
                        else
                            log.warn("Unknown sub-event "..subEvent)
                        end
                    end
                end
            end
        elseif event == "websocket_closed" then
            log.warn("WebSocket fermé. Reconnexion dans 5s.")
            sleep(5)
            self:connect()
        end
    end
end

--- Envoie un message dans le chat
function Twitch:send(channel, text)
    self.ws.send("PRIVMSG #" .. channel .. " :" .. text)
end

--- Ajoute une chaine et rejoint immediatement (no-op si deja rejointe). Le
--- proxy WS ne prend la liste des chaines qu'au moment de la connexion (via
--- l'URL, voir connect()) : pas de commande JOIN a la volee, donc on
--- reconnecte avec la liste mise a jour. Bloquant le temps de la
--- reconnexion : a appeler depuis un thread separe de celui qui fait
--- tourner Twitch:start() (ex: le handler onUnknownSubhost d'un
--- ChatRouter), jamais depuis l'interieur de start() lui-meme.
function Twitch:join(channel)
    for _, existing in ipairs(self.channels) do
        if existing == channel then return end
    end
    table.insert(self.channels, channel)
    if self.ws then
        self.ws.close()
        self.ws = nil
    end
    self:connect()
end

return Twitch
