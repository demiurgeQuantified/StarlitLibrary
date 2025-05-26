local Bitwise = {}

---Gets the value of a specific bit in a number.
---This is optimised for the case where you only need to check one or two bits: if you want to analyse an entire number, it is far more efficient to convert the number to a binary string instead.
---@param int integer The bitwise number.
---@param pos integer Position from the right of the bit to check. The rightmost bit is index 1.
---@return boolean bit Value of the bit.
---@nodiscard
Bitwise.get = function(int, pos)
    local bit = 2^(pos - 1)

    int = int / bit
    -- round towards 0
    int = int - int % 1
    if int < 0 then
        int = int + 1
    end
    -- odd = present
    return int % 2 ~= 0
end

---Sets the value of a specific bit in a number. If the bit is already set, returns the original number.
---@param int integer The bitwise number.
---@param pos integer Position from the right of the bit to check. The rightmost bit is index 1.
---@param value boolean The value to set the bit to.
---@return integer int The modified number.
---@nodiscard
Bitwise.set = function(int, pos, value)
    local bit = 2^(pos - 1)
    local hasBit = Bitwise.get(int, pos)

    if hasBit then
        if not value then
            int = int - bit
        end
    elseif value then
        int = int + bit
    end

    return int
end

return Bitwise