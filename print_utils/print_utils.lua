-- print_utils.lua
-- Logs are written to the computer's own physical screen (term.native())
-- by default, even if the chat display has been redirected to a monitor
-- via term.redirect(). Call print_utils.setTarget() to point logs at a
-- specific window instead (e.g. a screen region shared with another
-- program).

local print_utils = {}

local nativeTerm = term.native()

--- Redirige les logs vers une fenetre donnee au lieu du term physique
--- entier (ex: cet ordinateur partage son ecran avec un autre programme).
function print_utils.setTarget(win)
    nativeTerm = win
end

local level_colors = {
    info  = colors.white,
    warn  = colors.yellow,
    error = colors.red,
    debug = colors.gray
}

-- Niveau minimum affiche, configurable via `set twitch.logLevel <niveau>`
-- dans le shell CraftOS (debug, info, warn ou error). "debug" par defaut,
-- pour ne rien changer au comportement existant tant que ce n'est pas
-- explicitement reduit.
local LEVEL_ORDER = { debug = 1, info = 2, warn = 3, error = 4 }
local SETTINGS_KEY = "twitch.logLevel"

if settings then
    settings.define(SETTINGS_KEY, {
        description = "Niveau de log minimum du programme Twitch (debug, info, warn, error)",
        default = "debug",
        type = "string",
    })
end

local function shouldLog(level)
    if not settings then return true end
    local configured = settings.get(SETTINGS_KEY, "debug")
    if not LEVEL_ORDER[configured] then configured = "debug" end
    return LEVEL_ORDER[level] >= LEVEL_ORDER[configured]
end

local function splitLines(text)
    local lines = {}
    for line in (text.."\n"):gmatch("(.-)\n") do
        table.insert(lines, line)
    end
    return lines
end

--- Replicates the global print() behaviour, but always against
--- nativeTerm regardless of what term is currently redirected to.
local function printLine(text)
    local w, h = nativeTerm.getSize()
    for _, segment in ipairs(splitLines(text)) do
        local remaining = segment
        repeat
            local x, y = nativeTerm.getCursorPos()
            local available = math.max(1, w - x + 1)
            nativeTerm.write(remaining:sub(1, available))
            remaining = remaining:sub(available + 1)
            local _, cy = nativeTerm.getCursorPos()
            if cy >= h then
                nativeTerm.scroll(1)
                nativeTerm.setCursorPos(1, h)
            else
                nativeTerm.setCursorPos(1, cy + 1)
            end
        until remaining == ""
    end
end

local function timestamp()
    local t = textutils.formatTime(os.time(), true)
    return "[" .. t .. "]"
end

local function raw_tostring(val)
    if type(val) == "string" then
        return '"' .. val .. '"'
    elseif type(val) == "boolean" then
        return val and "true" or "false"
    else
        return tostring(val)
    end
end

-- Affiche une structure complète (table) avec indentation
local function dump_table(tbl, indent, visited)
    indent = indent or 0
    visited = visited or {}

    if visited[tbl] then
        return string.rep(" ", indent) .. "<circular reference>"
    end
    visited[tbl] = true

    local lines = {}
    table.insert(lines, string.rep(" ", indent) .. "{")
    for k, v in pairs(tbl) do
        local keyStr = "[" .. raw_tostring(k) .. "]"
        if type(v) == "table" then
            table.insert(lines, string.rep(" ", indent + 2) .. keyStr .. " = " .. dump_table(v, indent + 2, visited))
        else
            local valStr = raw_tostring(v)
            table.insert(lines, string.rep(" ", indent + 2) .. keyStr .. " = " .. valStr)
        end
    end
    table.insert(lines, string.rep(" ", indent) .. "}")
    return table.concat(lines, "\n")
end

function print_utils.dump(obj)
    if type(obj) == "table" then
        return dump_table(obj)
    else
        return raw_tostring(obj)
    end
end

function print_utils.print_msg(level, msg)
    if nativeTerm.isColor() then
        nativeTerm.setTextColor(level_colors[level] or colors.white)
    end
    printLine(timestamp() .. " [" .. level:upper() .. "] " .. msg)
    if nativeTerm.isColor() then
        nativeTerm.setTextColor(colors.white)
    end
end

function print_utils.info(msg)
    if not shouldLog("info") then return end
    print_utils.print_msg("info", print_utils.dump(msg))
end

function print_utils.warn(msg)
    if not shouldLog("warn") then return end
    print_utils.print_msg("warn", print_utils.dump(msg))
end

function print_utils.error(msg)
    if not shouldLog("error") then return end
    print_utils.print_msg("error", print_utils.dump(msg))
end

function print_utils.debug(msg)
    if not shouldLog("debug") then return end
    print_utils.print_msg("debug", print_utils.dump(msg))
end

return print_utils
