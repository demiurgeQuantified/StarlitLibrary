local ItemSerialiser = require("Starlit/serialise/internal/ItemSerialiser")

---@class Starlit.SerialisedItemKey : Starlit.SerialisedItem
---@field saveType 8
---@field keyId integer
---@field numberOfKey integer

local ItemSerialiserKey = {}

---@param key Key
---@return Starlit.SerialisedItemKey
---@nodiscard
ItemSerialiserKey.serialise = function(key)
    local serialised = ItemSerialiser.serialise(key)

    ---@cast serialised Starlit.SerialisedItemKey
    serialised.keyId = key:getKeyId()
    serialised.numberOfKey = key:getNumberOfKey()

    return serialised
end

---@param serialised Starlit.SerialisedItemKey
---@return Key?
---@nodiscard
ItemSerialiserKey.deserialise = function(serialised)
    local key = ItemSerialiser.deserialise(serialised) --[[@as Key?]]
    if not key then
        return nil
    end

    key:setKeyId(serialised.keyId)
    key:setNumberOfKey(serialised.numberOfKey)

    return key
end

return ItemSerialiserKey