local ItemSerialiserClothing = require("Starlit/serialise/internal/ItemSerialiserClothing")

---@class Starlit.SerialisedItemAlarmClockClothing : Starlit.SerialisedItemClothing
---@field saveType 13
---@field alarmHour integer
---@field alarmMinute integer
---@field alarmSet boolean

local ItemSerialiserAlarmClockClothing = {}

---@param alarmClockClothing AlarmClockClothing
---@return Starlit.SerialisedItemAlarmClockClothing
---@nodiscard
ItemSerialiserAlarmClockClothing.serialise = function(alarmClockClothing)
    local serialised = ItemSerialiserClothing.serialise(alarmClockClothing)

    ---@cast serialised Starlit.SerialisedItemAlarmClockClothing
    serialised.alarmHour = alarmClockClothing:getHour()
    serialised.alarmMinute = alarmClockClothing:getMinute()
    serialised.alarmSet = alarmClockClothing:isAlarmSet()
    -- can't do ringSince, nbd

    return serialised
end

---@param serialised Starlit.SerialisedItemAlarmClockClothing
---@return AlarmClockClothing?
---@nodiscard
ItemSerialiserAlarmClockClothing.deserialise = function(serialised)
    local alarmClockClothing = ItemSerialiserClothing.deserialise(serialised) --[[@as AlarmClockClothing?]]
    if not alarmClockClothing then
        return nil
    end

    alarmClockClothing:setHour(serialised.alarmHour)
    alarmClockClothing:setMinute(serialised.alarmMinute)
    alarmClockClothing:setAlarmSet(serialised.alarmSet)

    return alarmClockClothing
end

return ItemSerialiserAlarmClockClothing