local PZEvents = {}

-- FIXME: override addEvent to add new events to the system, or events registered after this file runs won't be covered

-- storing filenames with their callbacks could be an optimisation

---Removes a callback from an event without a reference to the callback.
---@param event string Name of the targeted event.
---@param filename string Name of the file that added the callback. Should be the path after media/lua/, and should not include the file extension.
---@param index? number Index of the callback addition in the file. Allows targeting a specific callback when a file adds multiple callbacks to the same event. Defaults to 1.
---@return function? callback The callback that was removed, or nil if no callback was removed.
---@deprecated
PZEvents.removeCallback = function(event, filename, index)
    error("TIS removed reflection API, this module no longer works.")
end

return PZEvents