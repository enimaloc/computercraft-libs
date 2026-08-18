-- install.lua
-- Telecharge (ou met a jour) l'app Twitch dans /twitch/, installe ses libs
-- partagees dans /lib/, et se met a jour lui-meme. A executer depuis le
-- shell CraftOS sur le computer :
--   pastebin get <code> install   -- une seule fois, pour recuperer ce script
--   install                        -- ensuite, a chaque mise a jour

local REPO_RAW = "https://raw.githubusercontent.com/enimaloc/computercraft-libs/main/"
local APP_RAW = REPO_RAW .. "apps/twitch/"

local TARGET_DIR = "/twitch"

-- Libs partagees (github.com/enimaloc/computercraft-libs), installees a
-- part dans /lib/<nom>/ par l'installeur commun a toutes les apps.
local REQUIRED_LIBS = {
    "twitch_api",
    "print_utils",
    "text_utils",
    "color_utils",
    "override_loader",
    "animation",
}

-- Fichiers du programme : toujours re-telecharges (ecrasent la version locale)
local FILES = {
    "twitch.lua",
}

-- Fichiers de donnees : fusionnes (union des lignes) plutot qu'ecrases,
-- pour recuperer les nouvelles entrees distantes sans perdre les entrees
-- ajoutees localement.
local DATA_FILES = {
    "knownBots.txt",
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

--- Installe les libs de REQUIRED_LIBS via l'installeur commun du repo
--- (charge et execute directement depuis son contenu HTTP : les libs ne
--- sont pas encore sur disque, require() n'est pas encore utilisable).
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

local function writeBinaryFile(path, content)
    local file, openErr = fs.open(path, "wb")
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

--- Decodeur base64 minimal (CC:Tweaked n'en fournit pas). Utilise pour
--- transporter des assets binaires (ex: audio dfpwm) en toute securite via
--- le repo, qui ne stocke que du texte.
local B64_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

local function base64Decode(data)
    data = data:gsub("[^" .. B64_CHARS .. "=]", "")
    local decoded = {}
    local function idx(byte)
        if not byte or byte == 61 then return nil end
        return B64_CHARS:find(string.char(byte), 1, true) - 1
    end
    for i = 1, #data, 4 do
        local a, b, c, d = data:byte(i, i + 3)
        local va, vb, vc, vd = idx(a), idx(b), idx(c), idx(d)
        local n = (va or 0) * 262144 + (vb or 0) * 4096 + (vc or 0) * 64 + (vd or 0)
        table.insert(decoded, string.char(math.floor(n / 65536) % 256))
        if vc then table.insert(decoded, string.char(math.floor(n / 256) % 256)) end
        if vd then table.insert(decoded, string.char(n % 256)) end
    end
    return table.concat(decoded)
end

--- Fichier binaire (ex: audio) stocke en base64 dans le repo : decode et
--- ecrit a l'emplacement voulu (peut differer de TARGET_DIR). Cree le
--- dossier parent si besoin, pour un chemin comme /media/....
local function fetchAssetTo(name, path)
    local content, err = download(APP_RAW .. name)
    if not content then
        return false, err
    end
    local dir = fs.getDir(path)
    if dir ~= "" and not fs.exists(dir) then
        fs.makeDir(dir)
    end
    return writeBinaryFile(path, base64Decode(content))
end

local function splitLines(content)
    local lines = {}
    for line in (content.."\n"):gmatch("(.-)\n") do
        table.insert(lines, line)
    end
    return lines
end

local function readLocalLines(path)
    if not fs.exists(path) then return {} end
    local file = fs.open(path, "r")
    local lines = {}
    while true do
        local line = file.readLine()
        if not line then break end
        table.insert(lines, line)
    end
    file.close()
    return lines
end

--- Union de deux listes de lignes, sans doublon, en gardant l'ordre
--- d'apparition (locales d'abord). Permet d'ajouter les nouvelles entrees
--- distantes sans jamais perdre une entree ajoutee localement.
local function mergeUnique(existing, incoming)
    local seen = {}
    local merged = {}
    for _, list in ipairs({existing, incoming}) do
        for _, line in ipairs(list) do
            if line ~= "" and not seen[line] then
                seen[line] = true
                table.insert(merged, line)
            end
        end
    end
    return merged
end

--- Fusionne un fichier de donnees distant avec sa version locale (union des
--- lignes) au lieu de choisir entre tout ecraser ou ne rien faire.
local function mergeTo(name, path)
    local content, err = download(APP_RAW .. name)
    if not content then
        return false, err
    end
    local merged = mergeUnique(readLocalLines(path), splitLines(content))
    return writeFile(path, table.concat(merged, "\n") .. "\n")
end

--- Un computer recoit un override du manifeste si son id figure dans
--- entry.ids OU son label figure dans entry.labels (OR, pas AND). Une
--- entree sans ids ni labels est invalide et ne matche jamais personne.
local function computerMatches(entry)
    if not (entry.ids or entry.labels) then
        return false
    end
    local id = os.computerID()
    if entry.ids then
        for _, entryId in ipairs(entry.ids) do
            if entryId == id then return true end
        end
    end
    local label = os.computerLabel()
    if entry.labels and label then
        for _, entryLabel in ipairs(entry.labels) do
            if entryLabel == label then return true end
        end
    end
    return false
end

--- Ne garde que les entrees d'overrides.json ciblant ce computer, et
--- recupere (toujours ecrase, jamais fusionne) les fichiers correspondants.
--- N'efface jamais un override local qui ne matche plus : install.lua
--- reste non destructif.
local function installOverrides()
    local manifestContent, err = download(APP_RAW .. "overrides.json")
    if not manifestContent then
        print("[ECHEC] overrides.json : " .. tostring(err))
        return 0, 1
    end

    local manifest = textutils.unserialiseJSON(manifestContent)
    if not manifest then
        print("[ECHEC] overrides.json : JSON invalide")
        return 0, 1
    end

    local okCount, failCount = 0, 0
    for _, entry in ipairs(manifest) do
        if entry.name and computerMatches(entry) then
            local ok, fetchErr
            if entry.type == "asset" then
                if entry.path then
                    ok, fetchErr = fetchAssetTo(entry.name, entry.path)
                else
                    ok, fetchErr = false, "asset sans champ \"path\""
                end
            else
                ok, fetchErr = fetchTo(entry.name, fs.combine(TARGET_DIR, entry.name))
            end
            if ok then
                print("[OK] " .. entry.name .. " (override)")
                okCount = okCount + 1
            else
                print("[ECHEC] " .. entry.name .. " : " .. tostring(fetchErr))
                failCount = failCount + 1
            end
        end
    end
    return okCount, failCount
end

--- Remplace le fichier en cours d'execution par la version du repo.
--- La mise a jour ne prend effet qu'au prochain lancement de "install".
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

local function install()
    selfUpdate()

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

    for _, name in ipairs(DATA_FILES) do
        local path = fs.combine(TARGET_DIR, name)
        local ok, fileErr = mergeTo(name, path)
        if ok then
            print("[OK] " .. name .. " (fusionne)")
            okCount = okCount + 1
        else
            print("[ECHEC] " .. name .. " : " .. tostring(fileErr))
            failCount = failCount + 1
        end
    end

    local overrideOk, overrideFail = installOverrides()
    okCount = okCount + overrideOk
    failCount = failCount + overrideFail

    print(("Termine : %d fichier(s) a jour, %d echec(s)."):format(okCount, failCount))
end

install()
