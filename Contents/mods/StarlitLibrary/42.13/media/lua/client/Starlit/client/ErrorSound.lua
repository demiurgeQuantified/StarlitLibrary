-- FIXME: disabled for now as it doesn't really work + needs a toggle
-- the sound plays after the error, not before, so if you have the debugger on
-- it only plays after you've dismissed it lol


-- -- TODO: user config to turn this on?
-- if not require("Starlit/Globals").isDebug then return end

-- local errorCount = 0

-- local checkError = function()
--     local newErrorCount = getLuaDebuggerErrorCount()
--     if newErrorCount ~= errorCount then
--         errorCount = newErrorCount
--         getSoundManager():playUISound("StarlitError")
--     end
-- end

-- -- TODO: this fires after the debugger opens
-- Events.OnTickEvenPaused.Add(checkError)

-- local old_onBreak = DoLuaDebuggerOnBreak
-- DoLuaDebuggerOnBreak = function(...)
--     checkError()
--     old_onBreak(...)
-- end

-- Events.OnResetLua.Add(function(reason)
--     errorCount = getLuaDebuggerErrorCount()
-- end)