---@namespace starlit

---Object oriented reimplementation of events. Performs slightly faster and fixes some bugs as well as providing some utilities
---@class LuaEvent<T...>
---@field [integer] function
local LuaEvent = {}
---@type LuaEvent[]
LuaEvent._list = {}
LuaEvent.__index = LuaEvent

---Creates a new event and registers it in the event list
---@return LuaEvent
---@nodiscard
function LuaEvent.new()
    local o = table.newarray() --[[@as table]]

    setmetatable(o, LuaEvent)
    table.insert(LuaEvent._list, o)

    return o
end

---Adds a new listener to be executed last
---@param listener fun(...:T...) The listener
function LuaEvent:addListener(listener)
    if not listener then
        return
    end
    table.insert(self, 1, listener)
end

---Adds a new listener to be executed first
---@param listener fun(...:T...) The listener
function LuaEvent:addListenerFront(listener)
    self[#self+1] = listener
end

---Adds a new listener to be executed before the target. Does nothing if the target is not a registered listener
---@param target fun(...:T...)
---@param listener fun(...:T...)
function LuaEvent:addListenerBefore(target, listener)
    if not listener then
        return
    end
    for i = 1, #self do
        if self[i] == target then
            table.insert(self, i+1, listener)
            return
        end
    end
end

---Adds a new listener to be executed after the target. Does nothing if the target is not a registered listener
---@param target fun(...:T...)
---@param listener fun(...:T...)
function LuaEvent:addListenerAfter(target, listener)
    if not listener then
        return
    end
    for i = 1, #self do
        if self[i] == target then
            table.insert(self, i, listener)
            return
        end
    end
end

---Removes all instances of a listener from execution.
---@param target fun(...:T...)
function LuaEvent:removeListener(target)
    for i = #self, 1, -1 do
        if self[i] == target then
            table.remove(self, i)
        end
    end
end

---Removes all event listeners
function LuaEvent:removeAllListeners()
    for i = 1, #self do
        self[i] = nil
    end
end

---Triggers all event listener functions with the arguments passed
---@param ... T...
function LuaEvent:trigger(...)
    for i = #self, 1, -1 do
        self[i](...)
    end
end

local _reloadLuaFile = reloadLuaFile
---@param filename string
reloadLuaFile = function(filename)
    for i = 1, #LuaEvent._list do
        local event = LuaEvent._list[i]
        for j = #event, 1, -1 do
            if getFilenameOfClosure(event[j]) == filename then
                table.remove(event, j)
            end
        end
    end
    _reloadLuaFile(filename)
end

return LuaEvent