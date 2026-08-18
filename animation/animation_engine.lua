-- animation_engine.lua
-- Dessine dans une fenetre dediee (voir animationEngine.setTarget), pas
-- dans le term global : le chat, qui vit dans sa propre fenetre plein
-- ecran, n'est ainsi jamais interrompu ni redessine par une animation.
local animationEngine = {}

local animationQueue = {}
local animations = {}
local target = term

-- === Fonctions internes ===
local function drawCenteredLine(data, y)
  local w = target.getSize()
  local txt = type(data) == "table" and data.text or tostring(data)
  local fg = type(data) == "table" and (data.fg or "f"):rep(#txt) or string.rep("f", #txt)
  local bg = type(data) == "table" and (data.bg or "0"):rep(#txt) or string.rep("0", #txt)
  local x = math.floor((w - #txt) / 2) + 1
  target.setCursorPos(x, y)
  target.blit(txt, fg, bg)
end

local function drawFrame(frame, overlayTextLines)
  os.queueEvent("animation_frame_draw_started")
  local w, h = target.getSize()
  overlayTextLines = overlayTextLines or {}
  local textLines = #overlayTextLines
  local spriteH = #frame.text
  local spriteW = #frame.text[1]
  local totalH = spriteH + textLines
  local yStart = math.floor((h - totalH) / 2)

  for i, line in ipairs(overlayTextLines) do
    drawCenteredLine(line, yStart + i - 1)
  end

  local spriteY = yStart + textLines
  local spriteX = math.floor((w - spriteW) / 2) + 1
  for i = 1, spriteH do
    local txt = frame.text[i]
    local fg = frame.fg[i]
    local bg = frame.bg and frame.bg[i] or ("0"):rep(#txt)

    for j = 1, #txt do
      local char = txt:sub(j,j)
      local fgChar = fg:sub(j,j)
      local bgChar = bg:sub(j,j)

      if not (fgChar == " " and bgChar == " ") then
        target.setCursorPos(spriteX + j - 1, spriteY + i - 1)
        target.blit(char, bgChar, fgChar)
      end
    end
  end
  os.queueEvent("animation_frame_draw_end")
end

local function playAnimation(frames, delay, overlayText)
  os.queueEvent("animation_start")
  for _, frame in ipairs(frames) do
    drawFrame(frame, overlayText)
    sleep(delay)
  end
  os.queueEvent("animation_end")
end

local function normalizeOverlayText(text)
  local lines = {}
  if type(text) == "string" then
    lines = { { text = text } }
  elseif type(text) == "table" and text[1] then
    for _, line in ipairs(text) do
      if type(line) == "string" then
        table.insert(lines, { text = line })
      else
        table.insert(lines, line)
      end
    end
  end
  return lines
end

-- === API publique ===

--- Ajoute une animation (nom + frames, ou fonction génératrice () -> frames
--- pour une animation procédurale calculée à chaque lecture)
function animationEngine.define(name, framesOrGenerator)
  animations[name] = framesOrGenerator
end

--- Change la fenetre/terminal dans lequel les animations sont dessinees
--- (typiquement un petit coin de l'ecran, distinct du chat).
function animationEngine.setTarget(newTarget)
  target = newTarget
end

--- Taille de la fenetre d'animation actuelle, utile aux générateurs procéduraux
function animationEngine.getSize()
  return target.getSize()
end

local function resolveFrames(anim)
  if type(anim) == "function" then
    return anim()
  end
  return anim
end

-- Nombre max d'animations en attente : au-dela, un afflux d'evenements
-- (train de cheers/subs) creerait plusieurs minutes de retard d'affichage.
-- On garde les plus recentes plutot que de laisser la file grossir.
local MAX_QUEUE = 10

--- Enfile une animation (par nom) dans la file d’attente
function animationEngine.queue(name, delay, overlayText)
  if #animationQueue >= MAX_QUEUE then
    table.remove(animationQueue, 1)
  end
  table.insert(animationQueue, {
    name = name,
    delay = delay or 0.3,
    text = overlayText,
  })
end

--- Lance la boucle principale bloquante
function animationEngine.run(defaultAnimation, defaultDelay)
  while true do
    if #animationQueue == 0 then
      local frames = resolveFrames(animations[defaultAnimation])
      if frames then
        playAnimation(frames, defaultDelay or 0.3)
      else
        sleep(1)
      end
    else
      local item = table.remove(animationQueue, 1)
      local frames = resolveFrames(animations[item.name])
      if frames then
        local lines = normalizeOverlayText(item.text)
        playAnimation(frames, item.delay, lines)
      end
    end
  end
end

return animationEngine
