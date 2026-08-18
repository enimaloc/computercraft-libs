-- install.lua
-- Installeur commun a toutes les libs de github.com/enimaloc/computercraft-libs.
-- A appeler depuis le install.lua d'une app pour installer les libs dont
-- elle depend, en plus de ses propres fichiers d'app.
--
-- Usage, depuis le install.lua d'une app (qui n'a pas encore ses libs sur
-- disque, donc pas de package.path/require possible : on charge ce script
-- directement depuis son contenu HTTP) :
--   local response = http.get(
--       "https://raw.githubusercontent.com/enimaloc/computercraft-libs/main/install.lua")
--   local installLibs = load(response.readAll(), "install-libs", "t", _ENV)()
--   response.close()
--   local okCount, failCount = installLibs({ "twitch_api", "print_utils" })
--
-- Installe toujours bootstrap.lua (necessaire a toute app) en plus des
-- libs demandees. Ecrase la version locale de chaque fichier -- comme
-- install.lua pour les apps, non fusionne (voir la limite de mergeTo la-bas
-- pour les fichiers de donnees, qui ne s'applique pas ici).
local REPO_RAW = "https://raw.githubusercontent.com/enimaloc/computercraft-libs/main/"
local LIB_DIR = "/lib"

local function download(url)
    local response, err = http.get(url)
    if not response then
        return nil, err or "requete http echouee"
    end
    local content = response.readAll()
    response.close()
    return content
end

local function fetchManifest()
    local content, err = download(REPO_RAW .. "manifest.json")
    if not content then
        return nil, err
    end
    local manifest = textutils.unserialiseJSON(content)
    if not manifest then
        return nil, "manifest.json invalide"
    end
    return manifest
end

local function writeFile(path, content)
    local dir = fs.getDir(path)
    if dir ~= "" and not fs.exists(dir) then
        fs.makeDir(dir)
    end
    local file, err = fs.open(path, "w")
    if not file then
        return false, err or "impossible d'ouvrir le fichier en ecriture"
    end
    file.write(content)
    file.close()
    return true
end

--- Telecharge et ecrit un seul fichier distant (sRepoPath) vers
--- LIB_DIR/sLocalPath. Compte OK/ECHEC pour l'appelant.
local function installFile(sRepoPath, sLocalPath)
    local content, err = download(REPO_RAW .. sRepoPath)
    if not content then
        print("[ECHEC] " .. sRepoPath .. " : " .. tostring(err))
        return false
    end
    local ok, writeErr = writeFile(fs.combine(LIB_DIR, sLocalPath), content)
    if not ok then
        print("[ECHEC] " .. sRepoPath .. " : " .. tostring(writeErr))
        return false
    end
    print("[OK] " .. sRepoPath)
    return true
end

--- tLibNames : liste des noms de libs a installer (cles de manifest.json),
--- ex: { "twitch_api", "print_utils", "animation" }.
--- Renvoie okCount, failCount.
return function(tLibNames)
    local okCount, failCount = 0, 0

    if installFile("bootstrap.lua", "bootstrap.lua") then
        okCount = okCount + 1
    else
        failCount = failCount + 1
    end

    local manifest, err = fetchManifest()
    if not manifest then
        print("[ECHEC] manifest.json : " .. tostring(err))
        return okCount, failCount + 1
    end

    for _, sLibName in ipairs(tLibNames) do
        local tFiles = manifest[sLibName]
        if not tFiles then
            print("[ECHEC] lib inconnue : " .. sLibName)
            failCount = failCount + 1
        else
            for _, sFileName in ipairs(tFiles) do
                local sPath = sLibName .. "/" .. sFileName
                if installFile(sPath, sPath) then
                    okCount = okCount + 1
                else
                    failCount = failCount + 1
                end
            end
        end
    end

    return okCount, failCount
end
