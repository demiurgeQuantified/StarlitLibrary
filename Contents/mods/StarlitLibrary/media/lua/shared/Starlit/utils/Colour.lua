local Colour = {}

---0-1 RGB triplet
---@alias Starlit.Colour [number, number, number]

---Creates a colour from a ColorInfo.
---@param colorInfo ColorInfo The ColorInfo to copy from.
---@return Starlit.Colour colour
---@nodiscard
Colour.fromColorInfo = function(colorInfo)
    return table.newarray(colorInfo:getR(), colorInfo:getG(), colorInfo:getB())
end

---Creates a colour from a Color.
---@param color Color The Color to copy from.
---@return Starlit.Colour colour
---@nodiscard
Colour.fromColor = function(color)
    return table.newarray(color:getR(), color:getG(), color:getB())
end

---Linearly interpolates between two colours.
---@param a Starlit.Colour The first colour to interpolate between.
---@param b Starlit.Colour The second colour to interpolate between.
---@param amount number How much (from 0 to 1) to interplate the colours by. 0 is fully a, 1 is fully b.
---@return Starlit.Colour colour The resulting colour.
---@nodiscard
Colour.lerpColour = function(a, b, amount)
    local result = table.newarray() --[[@as Starlit.Colour]]

    for i = 1, 3 do
        result[i] = a[i] + (b[i] - a[i]) * amount
    end

    return result
end

return Colour