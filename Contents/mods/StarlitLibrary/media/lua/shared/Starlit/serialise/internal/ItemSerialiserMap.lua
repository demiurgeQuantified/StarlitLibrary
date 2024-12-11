local ItemSerialiser = require("Starlit/serialise/internal/ItemSerialiser")

---@class Starlit.SerialisedItemMap : Starlit.SerialisedItem
---@field saveType 14
---@field mapId string

local ItemSerialiserMap = {}

---@param map MapItem
---@return Starlit.SerialisedItemMap
---@nodiscard
ItemSerialiserMap.serialise = function(map)
    local serialised = ItemSerialiser.serialise(map)

    ---@cast serialised Starlit.SerialisedItemMap
    serialised.mapId = map:getMapID()
    -- absolutely no hope of doing symbols lol

    return serialised
end

---@param serialised Starlit.SerialisedItemMap
---@return MapItem?
---@nodiscard
ItemSerialiserMap.deserialise = function(serialised)
    local map = ItemSerialiser.deserialise(serialised) --[[@as MapItem?]]
    if not map then
        return nil
    end

    map:setMapID(serialised.mapId)

    return map
end

return ItemSerialiserMap