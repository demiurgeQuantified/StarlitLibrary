---Object oriented reimplementation of events. Performs slightly faster and fixes some bugs as well as providing some utilities
---@class Starlit.LuaEvent
---@field [integer] function
local LuaEvent = {}
---@type table<string, Starlit.LuaEvent>
LuaEvent.list = {}
LuaEvent.__index = LuaEvent

---Creates a new event and registers it in the event list
---@param name string? Name of the event. If nil it will not be registered to the event list.
---@return Starlit.LuaEvent
LuaEvent.new = function(name)
    local o = table.newarray() --[[@as table]]

    setmetatable(o, LuaEvent)
    if name then
        LuaEvent.list[name] = o
    end

    return o
end

---Adds a new listener to be executed last
---@param listener function The listener
LuaEvent.addListener = function(self, listener)
    if not listener then return end
    table.insert(self, 1, listener)
end

---Adds a new listener to be executed first
---@param listener function The listener
LuaEvent.addListenerFront = function(self, listener)
    self[#self+1] = listener
end

---Adds a new listener to be executed before the target. Does nothing if the target is not a registered listener
---@param target function
---@param listener function
LuaEvent.addListenerBefore = function(self, target, listener)
    if not listener then return end
    for i = 1, #self do
        if self[i] == target then
            table.insert(self, i+1, listener)
            return
        end
    end
end

---Adds a new listener to be executed after the target. Does nothing if the target is not a registered listener
---@param target function
---@param listener function
LuaEvent.addListenerAfter = function(self, target, listener)
    if not listener then return end
    for i = 1, #self do
        if self[i] == target then
            table.insert(self, i, listener)
            return
        end
    end
end

---Removes all instances of a listener from execution.
---@param target function
LuaEvent.removeListener = function(self, target)
    for i = #self, 1, -1 do
        if self[i] == target then
            table.remove(self, i)
        end
    end
end

---Removes all event listeners
LuaEvent.removeAllListeners = function(self)
    for i = 1, #self do
        self[i] = nil
    end
end

---Triggers all event listener functions with the arguments passed
LuaEvent.trigger = function(self, ...)
    for i = #self, 1, -1 do
        self[i](...)
    end
end

return LuaEvent