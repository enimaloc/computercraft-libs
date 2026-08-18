-- color_utils.lua

local colorPalette = {
    [colors.white]       = {r=0xFF, g=0xFF, b=0xFF},
    [colors.orange]      = {r=0xFF, g=0xA5, b=0x00},
    [colors.magenta]     = {r=0xFF, g=0x00, b=0xFF},
    [colors.lightBlue]   = {r=0xAD, g=0xD8, b=0xE6},
    [colors.yellow]      = {r=0xFF, g=0xFF, b=0x00},
    [colors.lime]        = {r=0x00, g=0xFF, b=0x00},
    [colors.pink]        = {r=0xFF, g=0xC0, b=0xCB},
    [colors.gray]        = {r=0x80, g=0x80, b=0x80},
    [colors.lightGray]   = {r=0xD3, g=0xD3, b=0xD3},
    [colors.cyan]        = {r=0x00, g=0xFF, b=0xFF},
    [colors.purple]      = {r=0x80, g=0x00, b=0x80},
    [colors.blue]        = {r=0x00, g=0x00, b=0xFF},
    [colors.brown]       = {r=0xA5, g=0x2A, b=0x2A},
    [colors.green]       = {r=0x00, g=0x80, b=0x00},
    [colors.red]         = {r=0xFF, g=0x00, b=0x00},
    -- colors.black est volontairement absent : le texte est dessine sur un
    -- fond noir, un pseudo noir serait donc invisible.
}

local colorNames = {
    [colors.white] = "white",
    [colors.orange] = "orange",
    [colors.magenta] = "magenta",
    [colors.lightBlue] = "lightBlue",
    [colors.yellow] = "yellow",
    [colors.lime] = "lime",
    [colors.pink] = "pink",
    [colors.gray] = "gray",
    [colors.lightGray] = "lightGray",
    [colors.cyan] = "cyan",
    [colors.purple] = "purple",
    [colors.blue] = "blue",
    [colors.brown] = "brown",
    [colors.green] = "green",
    [colors.red] = "red",
    [colors.black] = "black",
}

local M = {}

function M.hexToRGB(hex)
    hex = hex:gsub("#", "")
    return {
        r = tonumber(hex:sub(1,2), 16),
        g = tonumber(hex:sub(3,4), 16),
        b = tonumber(hex:sub(5,6), 16)
    }
end

function M.getClosestColor(hex)
    local target = M.hexToRGB(hex)
    local minDist = math.huge
    local closestColor = colors.white

    for color, rgb in pairs(colorPalette) do
        local dr = rgb.r - target.r
        local dg = rgb.g - target.g
        local db = rgb.b - target.b
        local dist = dr * dr + dg * dg + db * db
        if dist < minDist then
            minDist = dist
            closestColor = color
        end
    end

    return closestColor
end

function M.getColorName(color)
    return colorNames[color] or "unknown"
end

return M
