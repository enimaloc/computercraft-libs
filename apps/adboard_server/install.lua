-- install.lua
-- Telecharge (ou met a jour) l'app adboard_server dans /adboard_server/,
-- installe ses libs partagees dans /lib/, et se met a jour lui-meme.
-- A executer depuis le shell CraftOS sur le computer serveur :
--   pastebin get <code> install   -- une seule fois, pour recuperer ce script
--   install                        -- ensuite, a chaque mise a jour

local REPO_RAW = "https://raw.githubusercontent.com/enimaloc/computercraft-libs/main/"
local APP_RAW = REPO_RAW .. "apps/adboard_server/"

local TARGET_DIR = "/adboard_server"

local REQUIRED_LIBS = {
    "adboard_protocol",
}

local FILES = {
    "server.lua",
}

local function download(url)
    local response, err = http.get(url)
    if not response then
        return nil, err or "requete http echouee"
    end
    local content = response.readAll()
    response.close()
    return content
end

local function installSharedLibs()
    local content, err = download(REPO_RAW .. "install.lua")
    if not content then
        print("[ECHEC] installeur de libs : " .. tostring(err))
        return 0, 1
    end
    local chunk, loadErr = load(content, "install-libs", "t", _ENV)
    if not chunk then
        print("[ECHEC] installeur de libs : " .. tostring(loadErr))
        return 0, 1
    end
    return chunk()(REQUIRED_LIBS)
end

local function writeFile(path, content)
    local file, openErr = fs.open(path, "w")
    if not file then
        return false, openErr or "impossible d'ouvrir le fichier en ecriture"
    end
    file.write(content)
    file.close()
    return true
end

local function fetchTo(name, path)
    local content, err = download(APP_RAW .. name)
    if not content then
        return false, err
    end
    return writeFile(path, content)
end

local function selfUpdate()
    local content, err = download(APP_RAW .. "install.lua")
    if not content or content == "" then
        print("[ECHEC] auto-mise a jour du script : " .. tostring(err))
        return
    end
    local selfPath = shell.getRunningProgram()
    local ok, writeErr = writeFile(selfPath, content)
    if ok then
        print("[OK] install.lua (sera actif au prochain lancement)")
    else
        print("[ECHEC] auto-mise a jour du script : " .. tostring(writeErr))
    end
end

local function install(bSelfUpdate)
    if bSelfUpdate ~= false then
        selfUpdate()
    end

    if not fs.exists(TARGET_DIR) then
        fs.makeDir(TARGET_DIR)
    end

    local okCount, failCount = installSharedLibs()

    for _, name in ipairs(FILES) do
        local path = fs.combine(TARGET_DIR, name)
        local ok, fileErr = fetchTo(name, path)
        if ok then
            print("[OK] " .. name)
            okCount = okCount + 1
        else
            print("[ECHEC] " .. name .. " : " .. tostring(fileErr))
            failCount = failCount + 1
        end
    end

    print(("Termine : %d fichier(s) a jour, %d echec(s)."):format(okCount, failCount))
end

install(...)
