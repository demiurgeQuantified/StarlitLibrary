local CORE = getCore()

local Colour = {}

---0-1 RGBA
---@alias Starlit.Colour [number, number, number, number]

---Creates a colour from a ColorInfo.
---@param colorInfo ColorInfo The ColorInfo to copy from.
---@return Starlit.Colour colour
---@nodiscard
Colour.fromColorInfo = function(colorInfo)
    return table.newarray(colorInfo:getR(), colorInfo:getG(), colorInfo:getB(), 1)
end

---Creates a colour from a Color.
---@param color Color The Color to copy from.
---@return Starlit.Colour colour
---@nodiscard
Colour.fromColor = function(color)
    return table.newarray(color:getR(), color:getG(), color:getB(), 1)
end

---Linearly interpolates between two colours.
---@param a Starlit.Colour The first colour to interpolate between.
---@param b Starlit.Colour The second colour to interpolate between.
---@param amount number How much (from 0 to 1) to interplate the colours by. 0 is fully a, 1 is fully b.
---@return Starlit.Colour colour The resulting colour.
---@nodiscard
Colour.lerpColour = function(a, b, amount)
    local result = table.newarray() --[[@as Starlit.Colour]]

    for i = 1, 4 do
        result[i] = a[i] + (b[i] - a[i]) * amount
    end

    return result
end

---Returns the R,G,B values of a colour.
---@param colour Starlit.Colour The colour.
---@return number r, number g, number b
---@nodiscard
Colour.getRGB = function(colour)
    return colour[1], colour[2], colour[3]
end

---Returns the R,G,B,A values of a colour.
---@param colour Starlit.Colour The colour.
---@return number r, number g, number b, number a
---@nodiscard
Colour.getRGBA = function(colour)
    return colour[1], colour[2], colour[3], colour[4]
end

-- FIXME: these needs to be updated when the user changes their settings

---The user defined 'good colour'. Should be prefered to hard coded colours to indicate information is good.
Colour.goodColour = Colour.fromColorInfo(CORE:getGoodHighlitedColor())
---The user defined 'bad colour'. Should be prefered to hard coded colours to indicate information is bad.
Colour.badColour = Colour.fromColorInfo(CORE:getBadHighlitedColor())

return Colour