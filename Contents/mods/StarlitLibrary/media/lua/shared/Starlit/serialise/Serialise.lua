local ItemSerialiser = require("Starlit/serialise/internal/ItemSerialiser")
local ItemSerialiserWeapon = require("Starlit/serialise/internal/ItemSerialiserWeapon")
local ItemSerialiserFood = require("Starlit/serialise/internal/ItemSerialiserFood")
local ItemSerialiserLiterature = require("Starlit/serialise/internal/ItemSerialiserLiterature")
local ItemSerialiserDrainable = require("Starlit/serialise/internal/ItemSerialiserDrainable")
local ItemSerialiserClothing = require("Starlit/serialise/internal/ItemSerialiserClothing")
local ItemSerialiserContainer = require("Starlit/serialise/internal/ItemSerialiserContainer")
local ItemSerialiserKey = require("Starlit/serialise/internal/ItemSerialiserKey")
local ItemSerialiserMoveable = require("Starlit/serialise/internal/ItemSerialiserMoveable")
local ItemSerialiserRadio = require("Starlit/serialise/internal/ItemSerialiserRadio")
local ItemSerialiserAlarmClock = require("Starlit/serialise/internal/ItemSerialiserAlarmClock")
local ItemSerialiserAlarmClockClothing = require("Starlit/serialise/internal/ItemSerialiserAlarmClockClothing")
local ItemSerialiserMap = require("Starlit/serialise/internal/ItemSerialiserMap")

local SERIALISER_MAP = {
    [1] = ItemSerialiserWeapon,
    [2] = ItemSerialiserFood,
    [3] = ItemSerialiserLiterature,
    [4] = ItemSerialiserDrainable,
    [5] = ItemSerialiserClothing,
    [6] = ItemSerialiserContainer,
    [8] = ItemSerialiserKey,
    [10] = ItemSerialiserMoveable,
    [11] = ItemSerialiserRadio,
    [12] = ItemSerialiserAlarmClock,
    [13] = ItemSerialiserAlarmClockClothing,
    [14] = ItemSerialiserMap
}

local Serialise = {}

---Tests if an item can be serialised without losing any information. The resulting item from serialisation and then deserialisation will be absolutely identical.
---@param item InventoryItem The item to test.
---@return boolean canSerialiseLossless True if the item can be serialised without losing data. False otherwise.
---@nodiscard
Serialise.canSerialiseInventoryItemLosslessly = function(item)
    if item:getByteData() then
        return false
    end
    if instanceof(item, "MapItem") then
        return false
    end
    if instanceof(item, "InventoryContainer") then
        ---@cast item InventoryContainer
        if not item:getInventory():isEmpty() then
            return false
        end
    end

    return true
end

---Serialises an inventory item into a table which can be safely saved as mod data.
---@param item InventoryItem The item to serialise.
---@return Starlit.SerialisedItem serialisedItem
---@nodiscard
Serialise.serialiseInventoryItem = function(item)
    local serialiser = SERIALISER_MAP[item:getSaveType()] or ItemSerialiser
    ---@diagnostic disable-next-line: param-type-mismatch
    return serialiser.serialise(item)
end

---Deserialises a serialised item into an item instance.
---@param serialised Starlit.SerialisedItem The item to deserialise.
---@return InventoryItem? item
---@nodiscard
Serialise.deserialiseInventoryItem = function(serialised)
    local serialiser = SERIALISER_MAP[serialised.saveType] or ItemSerialiser
    ---@diagnostic disable-next-line: param-type-mismatch
    return serialiser.deserialise(serialised)
end

return Serialise