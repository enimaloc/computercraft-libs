-- bootstrap.lua
-- Partage par toutes les apps : configure package.path pour que leurs
-- require() resolvent aussi bien vers leur propre dossier que vers
-- n'importe quel dossier de /lib/, sans que chaque app n'ait a lister les
-- libs dont elle depend.
--
-- /lib/ est toujours a un emplacement absolu fixe sur le computer deploye
-- (voir l'installeur commun, lib/install.lua), independant de la ou vit
-- l'app elle-meme (/twitch/, /startup.lua a la racine, etc. -- la
-- profondeur varie par app). D'ou une constante absolue plutot qu'un
-- calcul relatif du genre fs.combine(programDir, "../lib") : ce dernier
-- devrait connaitre la profondeur exacte de programDir pour etre juste, et
-- fs.combine ne "clamp" pas les ".." au-dela de la racine (contrairement a
-- la plupart des implementations POSIX) -- un ".." de trop ou de pas assez
-- produit un chemin cassé plutot qu'une erreur visible.
--
-- Une lib est un simple sous-dossier de lib/ (ex: lib/print_utils/,
-- lib/animation/) : rien ne l'attache a une app en particulier, plusieurs
-- apps peuvent requerir la meme lib. Le nom du module recherche par
-- require() doit juste correspondre au nom de fichier dans ce dossier
-- (ex: require("print_utils") -> lib/print_utils/print_utils.lua).
--
-- Usage, en tete de l'entrypoint d'une app (projects/app/<nom>/xxx.lua) :
--   local programDir = fs.getDir(shell.getRunningProgram())
--   if programDir:sub(1, 1) ~= "/" then
--       programDir = "/" .. programDir
--   end
--   if fs.exists("/lib/bootstrap.lua") then
--       local file = fs.open("/lib/bootstrap.lua", "r")
--       local bootstrap = load(file.readAll(), "/lib/bootstrap.lua", "t", _ENV)
--       file.close()
--       bootstrap()(programDir)
--   end
-- load(..., "t", _ENV) plutot que dofile() : dofile() charge avec
-- l'environnement global brut, qui n'a pas require/package (injectes par
-- le shell uniquement dans l'environnement du programme en cours, pas
-- dans _G) -- _ENV explicite les transmet a bootstrap.lua.
local LIB_ROOT = "/lib"

return function(programDir)
    local path = programDir .. "/?.lua;"

    if fs.exists(LIB_ROOT) and fs.isDir(LIB_ROOT) then
        for _, name in ipairs(fs.list(LIB_ROOT)) do
            local dir = fs.combine(LIB_ROOT, name)
            if fs.isDir(dir) then
                -- fs.combine renvoie un chemin sans "/" en tete (meme si
                -- LIB_ROOT en a un) : sans le rajouter ici, cette entree de
                -- package.path serait recombinee avec le pwd du shell (voir
                -- le commentaire sur programDir plus haut) au lieu de rester
                -- ancree sur /lib.
                path = path .. "/" .. dir .. "/?.lua;"
            end
        end
    end

    package.path = path .. package.path
end
