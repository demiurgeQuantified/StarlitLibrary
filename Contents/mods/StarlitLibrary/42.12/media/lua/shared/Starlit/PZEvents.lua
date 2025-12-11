local Reflection = require("Starlit/utils/Reflection")

local eventMap = HashMap.new()
LuaEventManager.getEvents(ArrayList.new(), eventMap)

---@type {string: Event}
local events = transformIntoKahluaTable(eventMap)

---@param func function
---@return string
---@nodiscard
local getShortFilename = function(func)
    return string.match(getFilenameOfClosure(func), "media/lua/(.+).lua")
end

local PZEvents = {}

---@type {string : function[]}
PZEvents.callbacks = {}

for name, event in pairs(events) do
    local callbacks = table.newarray()
    local javaCallbacks = Reflection.getField(event, "callbacks")
    for i = 0, javaCallbacks:size() - 1 do
        callbacks[i + 1] = javaCallbacks:get(i)
    end
    PZEvents.callbacks[name] = callbacks
end

for name, event in pairs(Events) do
    local old_add = event.Add
    event.Add = function(callback)
        table.insert(PZEvents.callbacks[name], callback)
        old_add(callback)
    end

    local old_remove = event.Remove
    event.Remove = function(callback)
        local callbacks = PZEvents.callbacks[name]
        for i = 1, #callbacks do
            if callbacks[i] == callback then
                table.remove(callbacks, i)
                break
            end
        end
        old_remove(callback)
    end
end

-- FIXME: override addEvent to add new events to the system, or events registered after this file runs won't be covered

-- storing filenames with their callbacks could be an optimisation

---Removes a callback from an event without a reference to the callback.
---@param event string Name of the targeted event.
---@param filename string Name of the file that added the callback. Should be the path after media/lua/, and should not include the file extension.
---@param index? number Index of the callback addition in the file. Allows targeting a specific callback when a file adds multiple callbacks to the same event. Defaults to 1.
---@return function? callback The callback that was removed, or nil if no callback was removed.
PZEvents.removeCallback = function(event, filename, index)
    index = index or 1
    local foundCallbacks = 0

    local callbacks = PZEvents.callbacks[event]
    for i = 1, #callbacks do
        local callback = callbacks[i]
        if getShortFilename(callback) == filename then
            foundCallbacks = foundCallbacks + 1
            if foundCallbacks == index then
                -- it would be a little cheaper to call the original Remove function and table.remove from callbacks
                -- since Remove has to loop through callbacks to find the right index to remove, but we already have it here
                Events[event].Remove(callback)
                return callback
            end
        end
    end
end

-- TODO: some way to prevent a callback from being added in the future

return PZEvents