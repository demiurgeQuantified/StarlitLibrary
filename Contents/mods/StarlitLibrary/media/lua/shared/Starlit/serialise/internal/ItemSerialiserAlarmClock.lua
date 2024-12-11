local ItemSerialiser = require("Starlit/serialise/internal/ItemSerialiser")

---@class Starlit.SerialisedItemAlarmClock : Starlit.SerialisedItem
---@field saveType 12
---@field alarmHour integer
---@field alarmMinute integer
---@field alarmSet boolean

local ItemSerialiserAlarmClock = {}

---@param alarmClock AlarmClock
---@return Starlit.SerialisedItemAlarmClock
---@nodiscard
ItemSerialiserAlarmClock.serialise = function(alarmClock)
    local serialised = ItemSerialiser.serialise(alarmClock)

    ---@cast serialised Starlit.SerialisedItemAlarmClock
    serialised.alarmHour = alarmClock:getHour()
    serialised.alarmMinute = alarmClock:getMinute()
    serialised.alarmSet = alarmClock:isAlarmSet()
    -- can't do ringSince, nbd

    return serialised
end

---@param serialised Starlit.SerialisedItemAlarmClock
---@return AlarmClock?
---@nodiscard
ItemSerialiserAlarmClock.deserialise = function(serialised)
    local alarmClock = ItemSerialiser.deserialise(serialised) --[[@as AlarmClock?]]
    if not alarmClock then
        return nil
    end

    alarmClock:setHour(serialised.alarmHour)
    alarmClock:setMinute(serialised.alarmMinute)
    alarmClock:setAlarmSet(serialised.alarmSet)

    return alarmClock
end

return ItemSerialiserAlarmClock