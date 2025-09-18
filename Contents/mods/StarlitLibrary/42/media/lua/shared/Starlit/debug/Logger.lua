---@param str string
---@return string
local titlecase = function(str)
    return string.upper(string.sub(str, 1, 1)) .. string.sub(str, 2, -1)
end


---@class starlit.Logger
---@field protected _mod string
---@field minLevel "error"|"warn"|"info"|"debug"
---@overload fun(message:string, level?:"error"|"warn"|"info"|"debug", ...)
local Logger = {}
Logger.__index = Logger


---@type starlit.Logger
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


---@param message string
---@param level? "error"|"warn"|"info"|"debug"
---@param ... any
function Logger:__call(message, level, ...)
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


---@param message string
---@param ... any
function Logger:error(message, ...)
    self(message, "error", ...)
end


---@param message string
---@param ... any
function Logger:warn(message, ...)
    self(message, "warn", ...)
end


---@param message string
---@param ... any
function Logger:info(message, ...)
    self(message, "info", ...)
end


---@param message string
---@param ... any
function Logger:debug(message, ...)
    self(message, "debug", ...)
end


---@package
---@param mod string
---@param minLevel? "error"|"warn"|"info"|"debug"
---@return starlit.Logger
---@nodiscard
Logger.new = function(mod, minLevel)
    ---@type starlit.Logger
    local o = {
        _mod = mod,
        minLevel = minLevel or Logger.minLevel
    }
    setmetatable(o, Logger)

    return o
end


---@class starlit.FileLogger : starlit.Logger
---@field path string
---@overload fun(message:string, level?:"error"|"warn"|"info"|"debug", ...)
local FileLogger = {}

FileLogger.__index = FileLogger

setmetatable(FileLogger, Logger)


---@param self starlit.FileLogger
---@param message string
---@param level? "error"|"warn"|"info"|"debug"
---@param ... any
---@see Starlit.Logger.__call
function FileLogger:__call(message, level, ...)
    level = level or "info"
    if logLevelMap[level] <= logLevelMap[self.minLevel] then
        local formattedMessage = string.format("[%s] [%s] %s", self._mod, titlecase(level), string.format(message, ...))

        -- opening and closing the writer every message sucks, but closing the writer is the only way to flush the buffer
        --  any mechanism to flush after every X messages/ticks/etc is prone to log nothing when the game freezes or crashes
        local writer = getFileWriter(self.path, true, true)
        writer:writeln(formattedMessage)
        writer:close()
    end
end


---@package
---@param mod string
---@param minLevel? "error"|"warn"|"info"|"debug"
---@param path string
---@return starlit.FileLogger
---@nodiscard
FileLogger.new = function(mod, minLevel, path)
    local o = Logger.new(mod, minLevel)
    ---@cast o starlit.FileLogger
    o.path = path
    setmetatable(o, FileLogger)

    return o
end


StarlitLogger = Logger.new("Starlit Library")


local LoggerAPI = {}


---@param mod string Name of the mod
---@param path? string Optional path of a file to write to, relative to Zomboid/Lua/logs/{mod}/ <br> If no extension is included, .txt will be added <br> If this argument is not passed the logger will write to the game's logs instead, and errors will cause stack traces
---@return starlit.Logger logger
---@see Starlit.Logger.__call
---@nodiscard
LoggerAPI.getLogger = function(mod, path)
    if path then
        if not string.match(path, "%.") then
            path = path .. ".txt"
        end
        path = "logs/" .. mod .. "/" .. path

        -- this just empties the file
        local writer = getFileWriter(path, true, false)
        writer:close()

        if not writer then
            StarlitLogger("Could not open file %s for logging", "error", path)
        end

        return FileLogger.new(mod, nil, path)
    else
        return Logger.new(mod)
    end
end


return LoggerAPI