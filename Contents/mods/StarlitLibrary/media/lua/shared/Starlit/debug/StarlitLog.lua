local StarlitLog = {}

local Logger = require "Starlit/debug/Logger"

local StarlitLogger = Logger.getLogger("Starlit Library")

---@deprecated
---Prints messages, filtering out those below the logLevel
---@param level Starlit.LogLevel Level of the message
---@param mod string Mod from which the message originates
---@param message string Message to print. Can be a pattern string to be formatted
---@param ... any Variables to format into the message, if any
StarlitLog.log = function(level, mod, message, ...)
    StarlitLogger(level, message, ...)
end

---@deprecated
---Returns a function that logs with the given identifier. This is to simplify logging calls as in most cases your entire project will only use one identifier.
---@param mod string Identifier to use in messages logged through the returned function
---@return Starlit.Logger
StarlitLog.getLogger = function(mod)
    return Logger.new(mod)
end

return StarlitLog