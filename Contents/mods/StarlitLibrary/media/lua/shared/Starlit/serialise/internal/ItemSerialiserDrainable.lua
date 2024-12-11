local ItemSerialiser = require("Starlit/serialise/internal/ItemSerialiser")

---@class Starlit.SerialisedItemDrainable : Starlit.SerialisedItem
---@field saveType 4
---@field usedDelta number

local ItemSerialiserDrainable = {}

---@param drainable DrainableComboItem
---@return Starlit.SerialisedItemDrainable
---@nodiscard
ItemSerialiserDrainable.serialise = function(drainable)
    local serialised = ItemSerialiser.serialise(drainable)

    ---@cast serialised Starlit.SerialisedItemDrainable
    serialised.usedDelta = drainable:getUsedDelta()

    return serialised
end

---@param serialised Starlit.SerialisedItemDrainable
---@return DrainableComboItem?
---@nodiscard
ItemSerialiserDrainable.deserialise = function(serialised)
    local drainable = ItemSerialiser.deserialise(serialised) --[[@as DrainableComboItem?]]
    if not drainable then
        return nil
    end

    drainable:setUsedDelta(serialised.usedDelta)

    return drainable
end

return ItemSerialiserDrainable