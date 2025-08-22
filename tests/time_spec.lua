-- default sandbox setting
local MINUTES_PER_DAY = 90
local HOURS_PER_DAY = MINUTES_PER_DAY / 60

insulate("Time module", function()
    _G.getGameTime = function()
        return {
            getMinutesPerDay = function()
                -- default sandbox option
                return MINUTES_PER_DAY
            end
        }
    end
    _G.Events = {
        OnGameTimeLoaded = {
            Add = function(func)
                func()
            end
        }
    }

    local Time = require("Starlit/utils/Time")

    it("can convert real time to game time", function()
        assert.are.equal(Time.durationToGameTime(1), 24 / HOURS_PER_DAY)
        assert.are.equal(Time.durationToGameTime(24), 24 / HOURS_PER_DAY * 24)
    end)

    it("can convert game time to real time", function()
        assert.are.equal(Time.durationToRealTime(1), HOURS_PER_DAY / 24)
        assert.are.equal(Time.durationToRealTime(24), (HOURS_PER_DAY / 24) * 24)
    end)

    it("can format duration strings", function()
        assert.are.equal(Time.formatDuration(1), "1h")
        assert.are.equal(Time.formatDuration(1.5), "1h 30m")
        assert.are.equal(Time.formatDuration(24 * 5), "5d")

        -- 1 second + 1 minute + 1 hour + 1 day + 1 week + 1 month + 1 year
        local oneoneone = 1 / 60 / 60
                + 1 / 60
                + 1
                + 1 * 24
                + 1 * 24 * 7
                + 1 * 24 * 30
                + 1 * 24 * 365
        assert.are.equal(
            Time.formatDuration(oneoneone, "seconds", "years"),
            "1y 1mo 1w 1d 1h 1m 1s"
        )
        assert.are.equal(
            Time.formatDuration(oneoneone, "seconds", "months"),
            "13mo 1w 1d 1h 1m 1s"
        )
    end)
end)



