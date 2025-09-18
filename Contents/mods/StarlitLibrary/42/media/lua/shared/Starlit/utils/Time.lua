---@type GameTime
local GAMETIME
Events.OnGameTimeLoaded.Add(function()
    GAMETIME = getGameTime()
end)


---Time units recognised by the module.
---@alias starlit.Time.UnitName "seconds" | "minutes" | "hours" | "days" | "weeks" | "months" | "years"


---@class starlit.Time.Unit
---@field name string
---@field timeFactor number
---@field shortFormatString string
---@field longFormatString string


---@type table<integer, starlit.Time.Unit>
local TIME_UNITS = {
    {
        name = "seconds",
        timeFactor = 1 / 60 / 60,
        shortFormatString = "%ds",
        longFormatString = "%d seconds",
    },
    {
        name = "minutes",
        timeFactor = 1 / 60,
        shortFormatString = "%dm",
        longFormatString = "%d minutes",
    },
    {
        name = "hours",
        timeFactor = 1,
        shortFormatString = "%dh",
        longFormatString = "%d hours",
    },
    {
        name = "days",
        timeFactor = 24,
        shortFormatString = "%dd",
        longFormatString = "%d days",
    },
    {
        name = "weeks",
        timeFactor = 24 * 7,
        shortFormatString = "%dw",
        longFormatString = "%d weeks",
    },
    {
        name = "months",
        timeFactor = 24 * 30,
        shortFormatString = "%dmo",
        longFormatString = "%d months",
    },
    {
        name = "years",
        timeFactor = 24 * 365,
        shortFormatString = "%dy",
        longFormatString = "%d years",
    }
}


---@type table<string, integer>
local TIME_UNIT_INDEX_BY_NAME = {}
for k, v in pairs(TIME_UNITS) do
    TIME_UNIT_INDEX_BY_NAME[v.name] = k
end

---Contains utilities for working with real and game time values. For scheduling functions, see TaskManager.
local Time = {}


---Formats a string describing a time duration. The result is suitable for display to the user.
---@param time number Duration in hours.
---@param minUnit starlit.Time.UnitName | nil Smallest unit to render the time in. If nil, a reasonable value will be calculated.
---@param maxUnit starlit.Time.UnitName | nil Largest unit to render the time in. If nil, a reasonable value will be calculated.
---@return string # String description of the duration <i>time</i>.
---@nodiscard
function Time.formatDuration(time, minUnit, maxUnit)
    local maxDetailIndex
    if not maxUnit then
        for i = #TIME_UNITS, minUnit ~= nil and TIME_UNIT_INDEX_BY_NAME[minUnit] or 1, -1 do
            if time >= TIME_UNITS[i].timeFactor then
                maxDetailIndex = i
                break
            end
        end
        if not maxDetailIndex then
            if minUnit then
                return string.format(TIME_UNITS[TIME_UNIT_INDEX_BY_NAME[minUnit]].shortFormatString, 0)
            else
                return string.format(TIME_UNITS[1].shortFormatString, 0)
            end
        end
    else
        maxDetailIndex = TIME_UNIT_INDEX_BY_NAME[maxUnit]
    end

    local minDetailIndex
    if not minUnit then
        if maxDetailIndex == #TIME_UNITS and time * TIME_UNITS[#TIME_UNITS].timeFactor > 10 then
            minDetailIndex = maxDetailIndex
        elseif maxDetailIndex > 1 then
            if time % TIME_UNITS[maxDetailIndex].timeFactor / TIME_UNITS[maxDetailIndex - 1].timeFactor >= 1 then
                minDetailIndex = maxDetailIndex - 1
            else
                minDetailIndex = maxDetailIndex
            end
        else
            minDetailIndex = 1
        end
    else
        minDetailIndex = TIME_UNIT_INDEX_BY_NAME[minUnit]
    end

    local str = ""

    for i = maxDetailIndex, minDetailIndex, -1 do
        if str ~= "" then
            str = str .. " "
        end

        if i ~= maxDetailIndex then
            time = time % TIME_UNITS[i + 1].timeFactor
        end

        -- TODO: replace usage of math.floor, it's expensive
        str = str .. string.format(
            TIME_UNITS[i].shortFormatString,
            math.floor(time / TIME_UNITS[i].timeFactor)
        )
    end

    return str
end


---Converts a game time duration to real time.
---@param time number Game time duration. The unit doesn't matter, but other functions in this module expect hours.
---@return number # Real time equivalent of <i>hours</i> in the same unit as given.
---@nodiscard
function Time.durationToRealTime(time)
    return time / 24 * (GAMETIME:getMinutesPerDay() / 60)
end


---Converts a real time duration to game time.
---@param time number Real time duration. The unit doesn't matter, but other functions in this module expect hours.
---@return number # Game time equivalent of <i>hours</i> in the same unit as given.
---@nodiscard
function Time.durationToGameTime(time)
    return time * 24 / (GAMETIME:getMinutesPerDay() / 60)
end


return Time