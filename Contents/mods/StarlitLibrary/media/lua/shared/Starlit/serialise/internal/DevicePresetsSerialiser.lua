---@class Starlit.SerialisedDevicePresets
---@field maxPresets integer
---@field presets table<string, integer>

local DevicePresetsSerialiser = {}

---@param devicePresets DevicePresets
---@return Starlit.SerialisedDevicePresets
---@nodiscard
DevicePresetsSerialiser.serialise = function(devicePresets)
    ---@type Starlit.SerialisedDevicePresets
    local serialised = {
        maxPresets = devicePresets:getMaxPresets(),
        presets = {}
    }

    local presets = devicePresets:getPresetsLua()
    for i = 1, #presets do
        local preset = presets[i]
        serialised.presets[preset.name] = preset.frequency
    end

    return serialised
end

---@param serialised Starlit.SerialisedDevicePresets
---@return DevicePresets
---@nodiscard
DevicePresetsSerialiser.deserialise = function(serialised)
    local presets = DevicePresets.new()

    presets:setMaxPresets(serialised.maxPresets)

    for name, frequency in pairs(serialised.presets) do
        presets:addPreset(name, frequency)
    end

    return presets
end

return DevicePresetsSerialiser