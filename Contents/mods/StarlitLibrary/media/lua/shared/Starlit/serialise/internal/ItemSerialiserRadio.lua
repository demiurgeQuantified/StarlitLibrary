local ItemSerialiser = require("Starlit/serialise/internal/ItemSerialiser")
local DeviceDataSerialiser = require("Starlit/serialise/internal/DeviceDataSerialiser")

---@class Starlit.SerialisedItemRadio : Starlit.SerialisedItem
---@field saveType 11
---@field deviceData Starlit.SerialisedDeviceData?

local ItemSerialiserRadio = {}

---@param radio Radio
---@return Starlit.SerialisedItemRadio
---@nodiscard
ItemSerialiserRadio.serialise = function(radio)
    local serialised = ItemSerialiser.serialise(radio)

    ---@cast serialised Starlit.SerialisedItemRadio
    local deviceData = radio:getDeviceData()
    if deviceData then
        serialised.deviceData = DeviceDataSerialiser.serialise(deviceData)
    end

    return serialised
end

---@param serialised Starlit.SerialisedItemRadio
---@return Radio?
---@nodiscard
ItemSerialiserRadio.deserialise = function(serialised)
    local radio = ItemSerialiser.deserialise(serialised) --[[@as Radio?]]
    if not radio then
        return nil
    end

    if serialised.deviceData then
        radio:setDeviceData(
            DeviceDataSerialiser.deserialise(serialised.deviceData)
        )
    end

    return radio
end

return ItemSerialiserRadio