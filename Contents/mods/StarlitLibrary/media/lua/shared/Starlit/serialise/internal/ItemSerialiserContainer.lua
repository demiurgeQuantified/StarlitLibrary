local ItemSerialiser = require("Starlit/serialise/internal/ItemSerialiser")

---@class Starlit.SerialisedItemContainer : Starlit.SerialisedItem
---@field saveType 6
---@field weightReduction integer

local ItemSerialiserContainer = {}

---@param container InventoryContainer
---@return Starlit.SerialisedItemContainer
---@nodiscard
ItemSerialiserContainer.serialise = function(container)
    local serialised = ItemSerialiser.serialise(container)
    ---@cast serialised Starlit.SerialisedItemContainer
    serialised.weightReduction = container:getWeightReduction()

    -- TODO: items in container

    return serialised
end

---@param serialised Starlit.SerialisedItemContainer
---@return InventoryContainer?
---@nodiscard
ItemSerialiserContainer.deserialise = function(serialised)
    local container = ItemSerialiser.deserialise(serialised) --[[@as InventoryContainer?]]
    if not container then
        return nil
    end

    container:setWeightReduction(serialised.weightReduction)

    return container
end

return ItemSerialiserContainer