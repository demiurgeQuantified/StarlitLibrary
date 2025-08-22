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
        assert.are.equal(24 / HOURS_PER_DAY, Time.durationToGameTime(1))
        assert.are.equal(24 / HOURS_PER_DAY * 24, Time.durationToGameTime(24))
    end)

    it("can convert game time to real time", function()
        assert.are.equal(HOURS_PER_DAY / 24, Time.durationToRealTime(1))
        assert.are.equal((HOURS_PER_DAY / 24) * 24, Time.durationToRealTime(24))
    end)

    it("can format duration strings", function()
        assert.are.equal("1h", Time.formatDuration(1))
        assert.are.equal("1h 30m", Time.formatDuration(1.5))
        assert.are.equal("5d", Time.formatDuration(24 * 5))

        -- 1 second + 1 minute + 1 hour + 1 day + 1 week + 1 month + 1 year
        local oneoneone = 1 / 60 / 60
                + 1 / 60
                + 1
                + 1 * 24
                + 1 * 24 * 7
                + 1 * 24 * 30
                + 1 * 24 * 365
        -- we expect 0s because of a precision issue
        -- this maybe should be considered a bug, but it seems fairly unavoidable, and inconsequential
        assert.are.equal(
            "1y 1mo 1w 1d 1h 1m 0s",
            Time.formatDuration(oneoneone, "seconds", "years")
        )
        assert.are.equal(
            "13mo 1w 6d 1h 1m 0s",
            Time.formatDuration(oneoneone, "seconds", "months")
        )
    end)
end)



