-- prout.override.lua
-- Override cible (voir overrides.json) : sur le computer #44 / label
-- "Tablette KaiLilou", joue /media/prout.dfpwm sur l'enceinte connectee
-- (s'il y en a une) a chaque fois que !prout apparait dans le chat.

local dfpwm = require("cc.audio.dfpwm")

local SOUND_PATH = "/media/prout.dfpwm"

local function playFile(speaker, path)
    local file = fs.open(path, "rb")
    if not file then return end

    local decoder = dfpwm.make_decoder()
    while true do
        local chunk = file.read(16 * 1024)
        if not chunk then break end
        local buffer = decoder(chunk)
        while not speaker.playAudio(buffer) do
            os.pullEvent("speaker_audio_empty")
        end
    end
    file.close()
end

return function(api)
    api.onCommand("prout", function(msg, args)
        local speaker = peripheral.find("speaker")
        if speaker then
            playFile(speaker, SOUND_PATH)
        end
    end)
end
