-- setup.lua
-- Point d'entree interactif : liste les apps enregistrees sur
-- github.com/enimaloc/computercraft-libs (voir apps.json) et installe
-- celle(s) choisies en executant leur propre install.lua. A executer
-- depuis le shell CraftOS sur un computer fraichement installe :
--   pastebin get <code> setup
--   setup

local REPO_RAW = "https://raw.githubusercontent.com/enimaloc/computercraft-libs/main/"

local function download(url)
    local response, err = http.get(url)
    if not response then
        return nil, err or "requete http echouee"
    end
    local content = response.readAll()
    response.close()
    return content
end

--- apps.json : { "nom" = "apps/nom/install.lua", ... }, genere par
--- push-to-repo.sh a partir de projects/app/.
local function fetchApps()
    local content, err = download(REPO_RAW .. "apps.json")
    if not content then
        return nil, err
    end
    local apps = textutils.unserialiseJSON(content)
    if not apps then
        return nil, "apps.json invalide"
    end
    return apps
end

--- Affiche la liste numerotee des apps et lit un choix : un ou plusieurs
--- numeros separes par des espaces, ou "all". Renvoie la liste des noms
--- d'app choisis (vide si rien de valide n'a ete saisi).
local function promptSelection(tAppNames)
    print("Apps disponibles :")
    for i, sName in ipairs(tAppNames) do
        print(("  %d) %s"):format(i, sName))
    end
    write("Choix (numeros separes par des espaces, ou \"all\") : ")
    local sInput = read() or ""

    if sInput:match("^%s*all%s*$") then
        return tAppNames
    end

    local tSelected = {}
    for sToken in sInput:gmatch("%S+") do
        local nIndex = tonumber(sToken)
        if nIndex and tAppNames[nIndex] then
            table.insert(tSelected, tAppNames[nIndex])
        else
            print("[IGNORE] choix invalide : " .. sToken)
        end
    end
    return tSelected
end

--- Telecharge et execute l'install.lua d'une app. Meme technique que
--- l'installeur de libs (voir install.lua) : l'app n'est pas encore sur
--- disque, dofile n'est pas utilisable -- on charge son contenu HTTP
--- directement et on l'execute dans l'environnement courant.
local function installApp(sName, sInstallPath)
    print("== Installation de " .. sName .. " ==")
    local content, err = download(REPO_RAW .. sInstallPath)
    if not content then
        print("[ECHEC] " .. sName .. " : " .. tostring(err))
        return false
    end
    local chunk, loadErr = load(content, sName .. "-install", "t", _ENV)
    if not chunk then
        print("[ECHEC] " .. sName .. " : " .. tostring(loadErr))
        return false
    end
    local ok, runErr = pcall(chunk)
    if not ok then
        print("[ECHEC] " .. sName .. " : " .. tostring(runErr))
        return false
    end
    return true
end

local function main()
    local apps, err = fetchApps()
    if not apps then
        print("[ECHEC] recuperation de la liste des apps : " .. tostring(err))
        return
    end

    local tAppNames = {}
    for sName in pairs(apps) do
        table.insert(tAppNames, sName)
    end
    table.sort(tAppNames)

    if #tAppNames == 0 then
        print("Aucune app disponible.")
        return
    end

    local tSelected = promptSelection(tAppNames)
    if #tSelected == 0 then
        print("Aucune app selectionnee.")
        return
    end

    for _, sName in ipairs(tSelected) do
        installApp(sName, apps[sName])
    end
end

main()
