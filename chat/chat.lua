-- chat.lua
-- Module headless pour le protocole de chat rednet : ouvre/ferme le modem,
-- gere le ping-pong et la connexion, et queue des evenements CC (os.queueEvent)
-- pour qu'un script consommateur se charge du rendu.

local function openModem()
    for _, sModem in ipairs(peripheral.getNames()) do
        if peripheral.getType(sModem) == "modem" then
            if not rednet.isOpen(sModem) then
                rednet.open(sModem)
            end
            return sModem
        end
    end
    return nil
end

local function closeModem(sModem)
    if sModem ~= nil then
        rednet.close(sModem)
    end
end

--------------------------------------------------------------------------
-- ChatHost
--------------------------------------------------------------------------

local ChatHost = {}
ChatHost.__index = ChatHost

--- tOptions (optionnel) :
---   commands   : table de commandes additionnelles/remplacantes, fusionnee
---                par-dessus les commandes par defaut (me/nick/users/help).
---   onMessage  : function(tUser, sText) -> bKeep, sTextOuRaison
---                Appele pour chaque message de chat normal (hors commande),
---                avant diffusion. bKeep == false rejette le message (le 2e
---                retour, si present, est renvoye en prive a l'auteur).
---   onNickname : function(sNewUsername, tUser) -> bKeep, sRaison
---                Appele a la connexion (tUser == nil) et sur /nick (tUser
---                == l'utilisateur qui se renomme). bKeep == false rejette
---                le pseudo (le 2e retour, si present, est renvoye en prive).
function ChatHost.new(sHostname, tOptions)
    tOptions = tOptions or {}

    local self = setmetatable({
        sHostname = sHostname,
        sOpenedModem = nil,
        tUsers = {},
        nUsers = 0,
        tPingPongTimer = {},
        onMessage = tOptions.onMessage,
        onNickname = tOptions.onNickname,
    }, ChatHost)

    self.tCommands = {
        ["me"] = function(tUser, sContent)
            if #sContent > 0 then
                self:send("* " .. tUser.sUsername .. " " .. sContent)
            else
                self:send("* Usage: /me [words]", tUser.nUserID)
            end
        end,
        ["nick"] = function(tUser, sContent)
            if #sContent == 0 then
                self:send("* Usage: /nick [nickname]", tUser.nUserID)
                return
            end
            if self.onNickname then
                local bKeep, sReason = self.onNickname(sContent, tUser)
                if bKeep == false then
                    self:send(sReason or ("* Nickname refused: " .. sContent), tUser.nUserID)
                    return
                end
            end
            local sOldName = tUser.sUsername
            tUser.sUsername = sContent
            self:send("* " .. sOldName .. " is now known as " .. tUser.sUsername)
        end,
        ["users"] = function(tUser, sContent)
            self:send("* Connected Users:", tUser.nUserID)
            local sUsers = "*"
            for _, tOtherUser in pairs(self.tUsers) do
                sUsers = sUsers .. " " .. tOtherUser.sUsername
            end
            self:send(sUsers, tUser.nUserID)
        end,
        ["help"] = function(tUser, sContent)
            self:send("* Available commands:", tUser.nUserID)
            local sCommands = "*"
            for sCommand in pairs(self.tCommands) do
                sCommands = sCommands .. " /" .. sCommand
            end
            self:send(sCommands .. " /logout", tUser.nUserID)
        end,
    }

    for sName, fnCommand in pairs(tOptions.commands or {}) do
        self.tCommands[sName] = fnCommand
    end

    return self
end

function ChatHost:send(sText, nUserID)
    if nUserID then
        local tUser = self.tUsers[nUserID]
        if tUser then
            rednet.send(tUser.nID, {
                sType = "text",
                nUserID = nUserID,
                sText = sText,
            }, "chat")
        end
    else
        for nUserID, tUser in pairs(self.tUsers) do
            rednet.send(tUser.nID, {
                sType = "text",
                nUserID = nUserID,
                sText = sText,
            }, "chat")
        end
    end
    os.queueEvent("chat_message", sText, nUserID)
end

--- Envoie un message affiche comme venant de sUsername (ex: "<sUsername> sText"),
--- sans qu'un utilisateur reel portant ce pseudo soit connecte : utile pour
--- des annonces serveur, un bot, ou parler sous un pseudo arbitraire depuis
--- le cote hote. nUserID optionnel pour un envoi prive a un utilisateur
--- connecte plutot qu'une diffusion a tous.
function ChatHost:sendAs(sUsername, sText, nUserID)
    self:send("<" .. sUsername .. "> " .. sText, nUserID)
end

function ChatHost:ping(nUserID)
    local tUser = self.tUsers[nUserID]
    rednet.send(tUser.nID, {
        sType = "ping to client",
        nUserID = nUserID,
    }, "chat")

    local timer = os.startTimer(15)
    tUser.bPingPonged = false
    self.tPingPongTimer[timer] = nUserID
end

--- Traite l'expiration (ou non) d'un timer de ping-pong. Utilise aussi
--- bien par ChatHost:runPingPong() (mode salon unique) que par ChatRouter
--- (mode multi-salons), qui possede seul la boucle os.pullEvent("timer")
--- et lui redirige les timers de ce salon -- voir handleMessage plus haut
--- pour le meme principe applique aux messages.
function ChatHost:handlePingTimeout(nTimerId)
    local nUserID = self.tPingPongTimer[nTimerId]
    if nUserID and self.tUsers[nUserID] then
        local tUser = self.tUsers[nUserID]
        if not tUser.bPingPonged then
            self:send("* " .. tUser.sUsername .. " has timed out")
            self.tUsers[nUserID] = nil
            self.nUsers = self.nUsers - 1
            os.queueEvent("chat_user_left", tUser.sUsername, nUserID)
        else
            self:ping(nUserID)
        end
    end
end

--- Boucle de ping-pong. Bloquant : a lancer dans un parallel.waitForAny.
function ChatHost:runPingPong()
    while true do
        local _, timer = os.pullEvent("timer")
        self:handlePingTimeout(timer)
    end
end

--- Traite un message "chat" recu (login/logout/chat/ping/pong) pour ce
--- salon. Utilise aussi bien par ChatHost:start() (mode salon unique) que
--- par ChatRouter (mode multi-salons), qui possede seul la boucle
--- rednet.receive() et lui redirige les messages de ce salon.
function ChatHost:handleMessage(nSenderID, tMessage)
    if type(tMessage) ~= "table" then
        return
    end

    if tMessage.sType == "login" then
        local nUserID = tMessage.nUserID
        local sUsername = tMessage.sUsername
        if nUserID and sUsername then
            if self.onNickname then
                local bKeep, sReason = self.onNickname(sUsername, nil)
                if bKeep == false then
                    rednet.send(nSenderID, {
                        sType = "text",
                        nUserID = nUserID,
                        sText = sReason or ("* Nickname refused: " .. sUsername),
                    }, "chat")
                    return
                end
            end
            self.tUsers[nUserID] = {
                nID = nSenderID,
                nUserID = nUserID,
                sUsername = sUsername,
            }
            self.nUsers = self.nUsers + 1
            os.queueEvent("chat_user_joined", sUsername, nUserID)
            self:send("* " .. sUsername .. " has joined the chat")
            self:ping(nUserID)
        end
        return
    end

    local nUserID = tMessage.nUserID
    local tUser = self.tUsers[nUserID]
    if not (tUser and tUser.nID == nSenderID) then
        return
    end

    if tMessage.sType == "logout" then
        self:send("* " .. tUser.sUsername .. " has left the chat")
        self.tUsers[nUserID] = nil
        self.nUsers = self.nUsers - 1
        os.queueEvent("chat_user_left", tUser.sUsername, nUserID)

    elseif tMessage.sType == "chat" then
        local sMessage = tMessage.sText
        if sMessage then
            local sCommand = string.match(sMessage, "^/([a-z]+)")
            if sCommand then
                local fnCommand = self.tCommands[sCommand]
                if fnCommand then
                    local sContent = string.sub(sMessage, #sCommand + 3)
                    fnCommand(tUser, sContent)
                else
                    self:send("* Unrecognised command: /" .. sCommand, tUser.nUserID)
                end
            else
                local sText = tMessage.sText
                if self.onMessage then
                    local bKeep, sResult = self.onMessage(tUser, sText)
                    if bKeep == false then
                        if sResult then
                            self:send(sResult, tUser.nUserID)
                        end
                        return
                    elseif sResult then
                        sText = sResult
                    end
                end
                self:send("<" .. tUser.sUsername .. "> " .. sText)
            end
        end

    elseif tMessage.sType == "ping to server" then
        rednet.send(tUser.nID, {
            sType = "pong to client",
            nUserID = nUserID,
        }, "chat")

    elseif tMessage.sType == "pong to server" then
        tUser.bPingPonged = true

    end
end

--- Demarre l'hebergement d'un salon seul. Bloquant : a lancer dans un
--- parallel.waitForAny aux cotes de la boucle de rendu du consommateur.
--- Pour heberger plusieurs salons sur le meme ordinateur, voir ChatRouter.
function ChatHost:start()
    self.sOpenedModem = openModem()
    if not self.sOpenedModem then
        os.queueEvent("chat_error", "No modems found.")
        return
    end
    rednet.host("chat", self.sHostname)

    local ok, err = pcall(parallel.waitForAny,
        function() self:runPingPong() end,
        function()
            while true do
                local nSenderID, tMessage = rednet.receive("chat")
                self:handleMessage(nSenderID, tMessage)
            end
        end
    )
    if not ok then
        os.queueEvent("chat_error", err)
    end

    self:stop()
end

--- Kick tous les clients, unhost et ferme le modem.
function ChatHost:stop()
    for nUserID, tUser in pairs(self.tUsers) do
        rednet.send(tUser.nID, {
            sType = "kick",
            nUserID = nUserID,
        }, "chat")
    end
    rednet.unhost("chat")
    closeModem(self.sOpenedModem)
    self.sOpenedModem = nil
end

--------------------------------------------------------------------------
-- ChatClient
--------------------------------------------------------------------------

local ChatClient = {}
ChatClient.__index = ChatClient

function ChatClient.new(sHostname, sUsername)
    return setmetatable({
        sHostname = sHostname,
        sUsername = sUsername,
        sOpenedModem = nil,
        nHostID = nil,
        nUserID = nil,
    }, ChatClient)
end

--- Cherche l'hote et se logue. Renvoie true, ou false + message d'erreur.
function ChatClient:connect()
    self.sOpenedModem = openModem()
    if not self.sOpenedModem then
        return false, "No modems found."
    end

    local nHostID = rednet.lookup("chat", self.sHostname)
    if nHostID == nil then
        return false, "Lookup failed."
    end
    self.nHostID = nHostID

    self.nUserID = math.random(1, 2147483647)
    rednet.send(self.nHostID, {
        sType = "login",
        nUserID = self.nUserID,
        sUsername = self.sUsername,
    }, "chat")

    return true
end

function ChatClient:send(sText)
    rednet.send(self.nHostID, {
        sType = "chat",
        nUserID = self.nUserID,
        sText = sText,
    }, "chat")
end

--- Boucle d'ecoute + ping-pong. Bloquant : a lancer dans un parallel.waitForAny
--- aux cotes de la boucle de rendu/saisie du consommateur. Queue :
--- chat_message(sText), chat_kicked(), chat_timeout()
function ChatClient:start()
    local bPingPonged = true
    local pingPongTimer = os.startTimer(0)

    local function ping()
        rednet.send(self.nHostID, {
            sType = "ping to server",
            nUserID = self.nUserID,
        }, "chat")
        bPingPonged = false
        pingPongTimer = os.startTimer(15)
    end

    local ok, err = pcall(parallel.waitForAny,
        function()
            while true do
                local sEvent, timer = os.pullEvent("timer")
                if timer == pingPongTimer then
                    if not bPingPonged then
                        os.queueEvent("chat_timeout")
                        return
                    else
                        ping()
                    end
                end
            end
        end,
        function()
            while true do
                local nSenderID, tMessage = rednet.receive("chat")
                if nSenderID == self.nHostID and type(tMessage) == "table" and tMessage.nUserID == self.nUserID then
                    if tMessage.sType == "text" then
                        if tMessage.sText then
                            os.queueEvent("chat_message", tMessage.sText)
                        end

                    elseif tMessage.sType == "ping to client" then
                        rednet.send(nSenderID, {
                            sType = "pong to server",
                            nUserID = self.nUserID,
                        }, "chat")

                    elseif tMessage.sType == "pong to client" then
                        bPingPonged = true

                    elseif tMessage.sType == "kick" then
                        os.queueEvent("chat_kicked")
                        return

                    end
                end
            end
        end
    )
    if not ok then
        os.queueEvent("chat_error", err)
    end
end

function ChatClient:logout()
    rednet.send(self.nHostID, {
        sType = "logout",
        nUserID = self.nUserID,
    }, "chat")
    closeModem(self.sOpenedModem)
    self.sOpenedModem = nil
end

--------------------------------------------------------------------------
-- ChatRouter
--------------------------------------------------------------------------
-- Permet d'heberger plusieurs salons (ChatHost) sur un seul ordinateur.
-- rednet.host() n'autorise qu'un seul hostname par protocole et par
-- ordinateur (voir rom/apis/rednet.lua) : le routeur repond donc lui-meme,
-- a la main, aux paquets "dns"/"lookup" pour chacun des salons enregistres,
-- avec le meme format que rednet.host. rednet.lookup (cote client, non
-- modifie) ne renvoie qu'un ID d'ordinateur, sans autre information : le
-- routeur retient donc quel salon chaque ordinateur emetteur a recherche
-- en dernier, pour aiguiller ensuite ses messages "chat" (login, texte,
-- ping...) vers le bon ChatHost, sans que le client n'ait besoin d'envoyer
-- le nom du salon lui-meme.
--
-- Limite : si un meme ordinateur cherche a rejoindre deux salons en
-- parallele, le routeur ne peut pas les distinguer (un seul salon retenu
-- par ID emetteur).

local ChatRouter = {}
ChatRouter.__index = ChatRouter

function ChatRouter.new()
    return setmetatable({
        sOpenedModem = nil,
        tRooms = {},
        tSenderRoom = {},
        tHostHandlers = {},
    }, ChatRouter)
end

--- Enregistre un ChatHost (deja cree via ChatHost.new(hostname)) sous son
--- propre hostname.
function ChatRouter:register(host)
    self.tRooms[host.sHostname] = host
end

--- Decoupe "sous-hote.hote" au premier point (ex: "enimaloc.twitch.tv" ->
--- "enimaloc", "twitch.tv"). nil si sHostname n'a pas de sous-domaine.
local function splitSubhost(sHostname)
    return sHostname:match("^([^.]+)%.(.+)$")
end

--- Enregistre un gestionnaire de fallback pour sHost (ex: "twitch.tv") :
--- appele quand un lookup pour "<sous-hote>.<sHost>" ne matche aucune
--- salle enregistree. fnHandler(sSubhost, nSenderID) doit renvoyer un
--- ChatHost (deja enregistre via router:register, ou cree puis enregistre
--- a la volee -- utile pour provisionner un salon a la demande et y
--- rediriger l'utilisateur), ou nil pour rejeter la demande (le lookup
--- echoue cote client, comme un hostname inconnu classique).
--- Le resultat est mis en cache sous le hostname complet demande : les
--- lookups suivants pour le meme sous-hote ne re-appellent pas fnHandler.
function ChatRouter:onUnknownSubhost(sHost, fnHandler)
    self.tHostHandlers[sHost] = fnHandler
end

--- Repond a un lookup DNS "chat" : exact match dans tRooms, sinon fallback
--- via tHostHandlers (voir onUnknownSubhost). Enregistre le salon trouve
--- comme salon courant de nSenderID pour router ses prochains messages.
function ChatRouter:handleLookup(nSenderID, sHostname)
    local host = self.tRooms[sHostname]

    if not host then
        local sSubhost, sHost = splitSubhost(sHostname)
        local fnHandler = sHost and self.tHostHandlers[sHost]
        if fnHandler then
            host = fnHandler(sSubhost, nSenderID)
            if host then
                -- Cache l'alias : les prochains lookups de ce hostname
                -- exact matchent directement, sans rappeler fnHandler.
                self.tRooms[sHostname] = host
            end
        end
    end

    if host then
        self.tSenderRoom[nSenderID] = sHostname
        rednet.send(nSenderID, {
            sType = "lookup response",
            sHostname = sHostname,
            sProtocol = "chat",
        }, "dns")
    end
end

--- Demarre le routeur : ouvre le modem, repond aux lookups, route les
--- messages vers le bon salon et distribue les timers de ping-pong.
--- Une seule boucle d'evenements (pas un thread de ping-pong par salon) :
--- necessaire pour que les salons crees a la volee par un handler de
--- onUnknownSubhost aient leur ping-pong actif des leur creation, sans
--- devoir relancer parallel.waitForAny. Bloquant : a lancer dans un
--- parallel.waitForAny aux cotes de la boucle de rendu du consommateur.
function ChatRouter:start()
    self.sOpenedModem = openModem()
    if not self.sOpenedModem then
        os.queueEvent("chat_error", "No modems found.")
        return
    end

    local function dispatch()
        while true do
            local event, a, b, c = os.pullEvent()

            if event == "rednet_message" then
                local nSenderID, tMessage, sProtocol = a, b, c
                if sProtocol == "dns" and type(tMessage) == "table" and tMessage.sType == "lookup"
                    and tMessage.sProtocol == "chat" then
                    self:handleLookup(nSenderID, tMessage.sHostname)

                elseif sProtocol == "chat" then
                    local sRoom = self.tSenderRoom[nSenderID]
                    local host = sRoom and self.tRooms[sRoom]
                    if host then
                        host:handleMessage(nSenderID, tMessage)
                    end
                end

            elseif event == "timer" then
                local nTimerId = a
                for _, host in pairs(self.tRooms) do
                    if host.tPingPongTimer[nTimerId] then
                        host:handlePingTimeout(nTimerId)
                        break
                    end
                end
            end
        end
    end

    local ok, err = pcall(dispatch)
    if not ok then
        os.queueEvent("chat_error", err)
    end

    self:stop()
end

--- Kick tous les utilisateurs de tous les salons et ferme le modem.
function ChatRouter:stop()
    for _, host in pairs(self.tRooms) do
        host:stop()
    end
    closeModem(self.sOpenedModem)
    self.sOpenedModem = nil
end

return {
    ChatHost = ChatHost,
    ChatClient = ChatClient,
    ChatRouter = ChatRouter,
}
