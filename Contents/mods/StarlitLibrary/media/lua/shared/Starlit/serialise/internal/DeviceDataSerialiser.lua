local DevicePresetsSerialiser = require("Starlit/serialise/internal/DevicePresetsSerialiser")

---@class DeviceData
---@field mediaItem string?

---@class Starlit.SerialisedDeviceData
---@field deviceName string
---@field twoWay boolean
---@field transmitRange integer
---@field micRange integer
---@field muted boolean
---@field baseVolumeRange number
---@field deviceVolume number
---@field portable boolean
---@field television boolean
---@field highTier boolean
---@field turnedOn boolean
---@field channel integer
---@field minChannelRange integer
---@field maxChannelRange integer
---@field batteryPowered boolean
---@field hasBattery boolean
---@field powerDelta number
---@field useDelta number
---@field headphoneType integer
---@field mediaIndex integer
---@field mediaType integer
---@field mediaItem string?
---@field noTransmit boolean
---@field presets Starlit.SerialisedDevicePresets?

local DeviceDataSerialiser = {}

---@param deviceData DeviceData
---@return Starlit.SerialisedDeviceData
---@nodiscard
DeviceDataSerialiser.serialise = function(deviceData)
    local serialised = {
        deviceName = deviceData:getDeviceName(),
        twoWay = deviceData:getIsTwoWay(),
        transmitRange = deviceData:getTransmitRange(),
        micRange = deviceData:getMicRange(),
        muted = deviceData:getMicIsMuted(),
        baseVolumeRange = deviceData:getBaseVolumeRange(),
        deviceVolume = deviceData:getDeviceVolume(),
        portable = deviceData:getIsPortable(),
        television = deviceData:getIsTelevision(),
        highTier = deviceData:getIsHighTier(),
        turnedOn = deviceData:getIsTurnedOn(),
        channel = deviceData:getChannel(),
        minChannelRange = deviceData:getMinChannelRange(),
        maxChannelRange = deviceData:getMaxChannelRange(),
        batteryPowered = deviceData:getIsBatteryPowered(),
        hasBattery = deviceData:getHasBattery(),
        powerDelta = deviceData:getPower(),
        useDelta = deviceData:getUseDelta(),
        headphoneType = deviceData:getHeadphoneType(),
        mediaIndex = deviceData:getMediaIndex(),
        mediaType = deviceData:getMediaType(),
        mediaItem = deviceData.mediaItem,
        noTransmit = deviceData:isNoTransmit(),
    }

    local devicePresets = deviceData:getDevicePresets()
    if devicePresets then
        serialised.presets = DevicePresetsSerialiser.serialise(devicePresets)
    end

    return serialised
end

---@param serialisedDeviceData Starlit.SerialisedDeviceData
---@return DeviceData
---@nodiscard
DeviceDataSerialiser.deserialise = function(serialisedDeviceData)
    local deviceData = DeviceData.new()

    deviceData:setDeviceName(serialisedDeviceData.deviceName)
    deviceData:setIsTwoWay(serialisedDeviceData.twoWay)
    deviceData:setTransmitRange(serialisedDeviceData.transmitRange)
    deviceData:setMicRange(serialisedDeviceData.micRange)
    deviceData:setMicIsMuted(serialisedDeviceData.muted)
    deviceData:setBaseVolumeRange(serialisedDeviceData.baseVolumeRange)
    deviceData:setDeviceVolume(serialisedDeviceData.deviceVolume)
    deviceData:setIsPortable(serialisedDeviceData.portable)
    deviceData:setIsTelevision(serialisedDeviceData.television)
    deviceData:setIsHighTier(serialisedDeviceData.highTier)
    deviceData:setTurnedOnRaw(serialisedDeviceData.turnedOn)
    deviceData:setChannel(serialisedDeviceData.channel)
    deviceData:setMinChannelRange(serialisedDeviceData.minChannelRange)
    deviceData:setMaxChannelRange(serialisedDeviceData.maxChannelRange)
    deviceData:setIsBatteryPowered(serialisedDeviceData.batteryPowered)
    deviceData:setHasBattery(serialisedDeviceData.hasBattery)
    deviceData:setPower(serialisedDeviceData.powerDelta)
    deviceData:setUseDelta(serialisedDeviceData.useDelta)
    deviceData:setHeadphoneType(serialisedDeviceData.headphoneType)
    deviceData:setMediaType(serialisedDeviceData.mediaType)
    if serialisedDeviceData.mediaItem then
        local mediaItem = InventoryItemFactory.CreateItem(serialisedDeviceData.mediaItem)
        mediaItem:setRecordedMediaIndexInteger(serialisedDeviceData.mediaIndex)
        deviceData:addMediaItem(mediaItem)
    end
    deviceData:setNoTransmit(serialisedDeviceData.noTransmit)

    if serialisedDeviceData.presets then
        deviceData:setDevicePresets(
            DevicePresetsSerialiser.deserialise(serialisedDeviceData.presets)
        )
    end

    return deviceData
end

return DeviceDataSerialiser