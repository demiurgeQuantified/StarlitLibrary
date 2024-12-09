---@class Starlit.Logger
---@field protected _mod string
---@field minLevel "error"|"warn"|"info"|"debug"
---@overload fun(message:string, level?:"error"|"warn"|"info"|"debug", ...)
local Logger = {}
Logger.__index = Logger

---@type Starlit.Logger
local StarlitLogger
local logLevelMap = {
    -- Critical problems that stop the mod from functioning
    error = 1,
    -- Non-critical problems
    warn = 2,
    -- Not necessarily bad but worth logging
    info = 3,
    -- Information that is not necessarily bad but useful for debugging
    debug = 4,
}

Logger.minLevel = getDebug() and "debug" or "info"

---@param str string
---@return string
local titlecase = function(str)
    return string.upper(string.sub(str, 1, 1)) .. string.sub(str, 2, -1)
end

---@param message string
---@param level? "error"|"warn"|"info"|"debug"
---@param ... any
Logger.__call = function(self, message, level, ...)
    level = level or "info"
    if logLevelMap[level] <= logLevelMap[self.minLevel] then
        local formattedMessage = string.format("[%s] [%s] %s", self._mod, titlecase(level), string.format(message, ...))
        if level == "error" then
            error(formattedMessage)
        else
            print(formattedMessage)
        end
    end
end

---@package
---@param mod string
---@param minLevel? "error"|"warn"|"info"|"debug"
---@return Starlit.Logger
Logger.new = function(mod, minLevel)
    ---@type Starlit.Logger
    local o = {
        _mod = mod,
        minLevel = minLevel or Logger.minLevel
    }
    ---@diagnostic disable-next-line: param-type-mismatch
    setmetatable(o, Logger)

    return o
end

---Cleans up resources used by the logger when it is no longer needed
Logger.destroy = function() end

---@class Starlit.FileLogger : Starlit.Logger
---@field protected _writer LuaFileWriter
---@overload fun(message:string, level?:"error"|"warn"|"info"|"debug", ...)
local FileLogger = {}

---@diagnostic disable-next-line: param-type-mismatch
setmetatable(FileLogger, Logger)

---@param message string
---@param level? "error"|"warn"|"info"|"debug"
---@param ... any
---@see Starlit.Logger.__call
FileLogger.__call = function(self, message, level, ...)
    level = level or "info"
    if logLevelMap[level] <= logLevelMap[self.minLevel] then
        local formattedMessage = string.format("[%s] [%s] %s", self._mod, titlecase(level), string.format(message, ...))
        self._writer:writeln(formattedMessage)
    end
end

---@package
---@param mod string
---@param minLevel? "error"|"warn"|"info"|"debug"
---@param writer LuaFileWriter
---@return Starlit.FileLogger
FileLogger.new = function(mod, minLevel, writer)
    local o = Logger.new(mod, minLevel)
    ---@cast o Starlit.FileLogger
    o._writer = writer
    ---@diagnostic disable-next-line: param-type-mismatch
    setmetatable(o, FileLogger)

    return o
end

FileLogger.destroy = function(self)
    self._writer:close()
end

StarlitLogger = Logger.new("Starlit Library")

local LoggerAPI = {}

---@param mod string Name of the mod
---@param file? string Optional path of a file to write to, relative to Zomboid/Lua/logs/{mod}/ <br> If no extension is included, .txt will be added <br> If this argument is not passed the logger will write to the game's logs instead, and errors will cause stack traces
---@return Starlit.Logger logger
---@see Starlit.Logger.__call
LoggerAPI.getLogger = function(mod, file)
    if file then
        if not string.match(file, "%.") then
            file = file .. ".txt"
        end
        file = "logs/" .. mod .. "/" .. file

        local writer = getFileWriter(file, true, false)
        if not writer then
            StarlitLogger(logLevelMap.ERROR, "Could not open file %s for logging", file)
        end

        return FileLogger.new(mod, nil, writer)
    else
        return Logger.new(mod)
    end
end

return LoggerAPI