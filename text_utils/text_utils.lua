-- text_utils.lua
-- CraftOS can only render its own limited glyph set, not arbitrary UTF-8.
-- sanitize() makes chat text safe to draw: known accented letters are
-- transliterated to their closest ASCII equivalent, everything else
-- outside ASCII becomes a single '?' per Unicode codepoint.

local text_utils = {}

local FALLBACK = "?"

local TRANSLIT = {
    [0x00C0] = "A", [0x00C1] = "A", [0x00C2] = "A", [0x00C3] = "A", [0x00C4] = "A", [0x00C5] = "A",
    [0x00C6] = "AE",
    [0x00C7] = "C",
    [0x00C8] = "E", [0x00C9] = "E", [0x00CA] = "E", [0x00CB] = "E",
    [0x00CC] = "I", [0x00CD] = "I", [0x00CE] = "I", [0x00CF] = "I",
    [0x00D1] = "N",
    [0x00D2] = "O", [0x00D3] = "O", [0x00D4] = "O", [0x00D5] = "O", [0x00D6] = "O", [0x00D8] = "O",
    [0x00D9] = "U", [0x00DA] = "U", [0x00DB] = "U", [0x00DC] = "U",
    [0x00DD] = "Y",
    [0x00E0] = "a", [0x00E1] = "a", [0x00E2] = "a", [0x00E3] = "a", [0x00E4] = "a", [0x00E5] = "a",
    [0x00E6] = "ae",
    [0x00E7] = "c",
    [0x00E8] = "e", [0x00E9] = "e", [0x00EA] = "e", [0x00EB] = "e",
    [0x00EC] = "i", [0x00ED] = "i", [0x00EE] = "i", [0x00EF] = "i",
    [0x00F1] = "n",
    [0x00F2] = "o", [0x00F3] = "o", [0x00F4] = "o", [0x00F5] = "o", [0x00F6] = "o", [0x00F8] = "o",
    [0x00F9] = "u", [0x00FA] = "u", [0x00FB] = "u", [0x00FC] = "u",
    [0x00FD] = "y", [0x00FF] = "y",
    [0x00DF] = "ss",
    [0x0152] = "OE", [0x0153] = "oe",
}

--- Decode the UTF-8 codepoint starting at byte index i.
--- Returns codepoint, next index. Falls back to a single-byte codepoint
--- (and next index i+1) on malformed input.
local function decodeCodepoint(s, i)
    local b1 = s:byte(i)
    if not b1 then return nil, i end
    if b1 < 0x80 then
        return b1, i + 1
    end

    local extra, codepoint
    if b1 >= 0xF0 then
        extra, codepoint = 3, b1 % 0x08
    elseif b1 >= 0xE0 then
        extra, codepoint = 2, b1 % 0x10
    elseif b1 >= 0xC0 then
        extra, codepoint = 1, b1 % 0x20
    else
        return b1, i + 1
    end

    for k = 1, extra do
        local b = s:byte(i + k)
        if not b or b < 0x80 or b >= 0xC0 then
            return b1, i + 1
        end
        codepoint = codepoint * 0x40 + (b % 0x40)
    end
    return codepoint, i + extra + 1
end

--- Make text safe to draw on a CraftOS terminal: known accented letters
--- are transliterated, everything else non-ASCII becomes '?'.
function text_utils.sanitize(text)
    if type(text) ~= "string" then return text end

    local out = {}
    local i, len = 1, #text
    while i <= len do
        local codepoint, nextI = decodeCodepoint(text, i)
        if not codepoint then break end
        if codepoint < 0x80 then
            table.insert(out, string.char(codepoint))
        else
            table.insert(out, TRANSLIT[codepoint] or FALLBACK)
        end
        i = nextI
    end
    return table.concat(out)
end

return text_utils
