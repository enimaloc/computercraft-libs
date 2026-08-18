-- bootstrap.lua
-- Partage par toutes les apps de projects/app/<nom>/ : configure
-- package.path pour que leurs require() resolvent aussi bien vers leur
-- propre dossier que vers n'importe quel dossier de projects/lib/, sans
-- que chaque app n'ait a lister les libs dont elle depend.
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
--   dofile(fs.combine(programDir, "../../lib/bootstrap.lua"))(programDir)
return function(programDir)
    local path = programDir .. "/?.lua;"

    local libRoot = fs.combine(programDir, "../../lib")
    if fs.exists(libRoot) and fs.isDir(libRoot) then
        for _, name in ipairs(fs.list(libRoot)) do
            local dir = fs.combine(libRoot, name)
            if fs.isDir(dir) then
                path = path .. dir .. "/?.lua;"
            end
        end
    end

    package.path = path .. package.path
end
