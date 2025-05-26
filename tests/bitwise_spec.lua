---@param str string
---@return integer
local function binaryStringToInteger(str)
    assert(type(str) == "string", "Non-string passed to binaryStringToInteger")
    local result = 0
    for i = 1, #str do
      if string.sub(str, i, i) == "1" then
          result = result + 2 ^ (#str - i)
      end
    end
    return result
end

---@param int integer
---@return string
local function integerToBinaryString(int)
    assert(type(int) == "number" and math.floor(int) == int, "Non-integer passed to integerToBinaryString")
    assert(int > 0, "FIXME: negative numbers not supported yet")
    local result = ""
    for i = 1, 32 do
        if (int / (2 ^ i - 1)) % 2 ~= 0 then
            result = result .. "1"
        else
            result = result .. "0"
        end
    end
    return result
end

local Bitwise = require("Starlit/utils/Bitwise")


describe("Bitwise module", function()
    it("can read bits", function()
        local binary = "00000111100110010100001111110011"
        local number = binaryStringToInteger(binary)
        for i = 1, #binary do
            local stringPos = #binary - i + 1
            local shouldBeSet = string.sub(binary, stringPos, stringPos) == "1"
            assert.are.equal(Bitwise.get(number, i), shouldBeSet)
        end
    end)
    it("can set bits", function()
        local binary = "01101111010100110101000111010001"
        assert.are.equal(Bitwise.set(binaryStringToInteger(binary), 29, true), binaryStringToInteger("01111111010100110101000111010001"))
        assert.are.equal(Bitwise.set(binaryStringToInteger(binary), 5, false), binaryStringToInteger("01101111010100110101000111000001"))
    end)
end)
