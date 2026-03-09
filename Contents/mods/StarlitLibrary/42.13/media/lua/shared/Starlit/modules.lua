---@namespace starlit.modules

local LuaEvent = require("Starlit/LuaEvent")

---@type table<string, table>
local delayedRequires = {}

---@type metatable
local uninitialisedMetatable = {
    __index = function()
        error("tried to index delayedRequire module before initialisation")
    end,
    __newindex = function()
        error("tried to index delayedRequire module before initialisation")
    end
}

local failedMetatable = {
    __index = function()
        error("tried to index delayedRequire module after initialisation failed")
    end,
    __newindex = function()
        error("tried to index delayedRequire module after initialisation failed")
    end
}





---Utilities for working with modules.
local modules = {}

---Triggered after all delayed requires have been loaded,
---@readonly
modules.onDelayedRequiresDone = LuaEvent.new()

local function initDelayedRequires()
    for moduleName, t in pairs(delayedRequires) do
        local module = require(moduleName)
        if type(module) ~= "table" then
            print("[Starlit] [WARNING]: delayedRequire to module " .. moduleName .. " did not return a table.")
            setmetatable(t, failedMetatable)
        else
            setmetatable(
                t,
                {
                    __index = module,
                    __newindex = module
                }
            )
        end
    end

    modules.onDelayedRequiresDone:trigger()
end

Events.OnInitGlobalModData.Add(initDelayedRequires)


---Requires a module after all modules have been initialised.
---
---This is needed when importing a client module from shared, or a server module from either client or shared.
---This is generally bad style and should be avoided, but often necessary for networked timed actions which must be shared but usually have server/client only paths.
---
---The result of this function is an empty table which, when ready, redirects indices to the correct module.
---If the module was not required yet or the require failed, an error is raised instead.
---
---There may be a slight overhead to using these over a raw module:
---Timed actions are rarely performance sensitive so this shouldn't be a concern generally,
---but if you need to squeeze out extra performance don't use this and delay manually using events.
---
---You will very likely want to annotate the return value of this function with @module `module`.
---@param module string Module path.
---@return table module Delayed require module.
function modules.delayedRequire(module)
    if not delayedRequires[module] then
        delayedRequires[module] = setmetatable({}, uninitialisedMetatable)        
    end

    return delayedRequires[module]
end


---Status of a delayed require module.
---@enum DelayedRequireStatus
modules.DelayedRequireStatus = {
    ---Delayed require has not been required yet.
    UNINITIALISED = 1,
    ---Delayed require failed.
    FAILED = 2,
    ---Delayed require succeeded.
    SUCCEEDED = 3,
}


---Gets the current status of a delayed require.
---
---Result is undefined if the argument is not a delayed require module.
---@param delayedRequire table Delayed require module.
---@return DelayedRequireStatus status Current status.
---@nodiscard
function modules.getDelayedRequireStatus(delayedRequire)
    local metatable = getmetatable(delayedRequire)
    if metatable == uninitialisedMetatable then
        return modules.DelayedRequireStatus.UNINITIALISED
    elseif metatable == failedMetatable then
        return modules.DelayedRequireStatus.FAILED
    end

    return modules.DelayedRequireStatus.SUCCEEDED
end


return modules