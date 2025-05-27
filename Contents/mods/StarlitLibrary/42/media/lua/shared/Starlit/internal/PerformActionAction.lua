local Actions = require("Starlit/action/Actions")

---@class starlit.PerformActionAction : ISBaseTimedAction
---@field actionState starlit.ActionState
local PerformActionAction = ISBaseTimedAction:derive("starlit.PerformActionAction")

PerformActionAction.isValid = function(self)
    return Actions.isActionStateStillValid(self.actionState)
end

PerformActionAction.update = function(self)
    self:setItemsJobDelta(self:getJobDelta())

    self.actionState.def.update(self.actionState)
    ISBaseTimedAction.update(self)
end

---@param delta number
PerformActionAction.setItemsJobDelta = function(self, delta)
    for _, item in pairs(self.actionState.items) do
        if type(item) == "table" then
            for i = 1, #item do
                item[i]:setJobDelta(delta)
            end
        else
            item:setJobDelta(delta)
        end
    end
end

---@param name string | nil
PerformActionAction.setItemsJobType = function(self, name)
    for _, item in pairs(self.actionState.items) do
        if type(item) == "table" then
            for i = 1, #item do
                item[i]:setJobType(name)
            end
        else
            item:setJobType(name)
        end
    end
end

PerformActionAction.cleanup = function(self)
    self:setItemsJobDelta(0)
    self:setItemsJobType(nil)
end

PerformActionAction.stop = function(self)
    self.actionState.def.stop(self.actionState)
    self:cleanup()
    ISBaseTimedAction.stop(self)
end

PerformActionAction.perform = function(self)
    self.actionState.def.complete(self.actionState)
    self:cleanup()
    ISBaseTimedAction.perform(self)
end

PerformActionAction.start = function(self)
    if not Actions.isActionStateStillValid(self.actionState) then
        -- TODO: in some situations we may want to build a new state instead of cancelling
        -- e.g. if i queued the action for later, even if i lost the item i was going to use for it
        -- i may still have a valid one
        self:forceStop()
        return
    end

    self:setItemsJobDelta(0)
    self:setItemsJobType(self.actionState.def.name)

    self.actionState.def.start(self.actionState)

    ISBaseTimedAction.start(self)
end

---@param state starlit.ActionState
---@return starlit.PerformActionAction action
PerformActionAction.new = function(state)
    local o = ISBaseTimedAction:new(state.character)
    setmetatable(o, PerformActionAction) ---@cast o starlit.PerformActionAction
    o.Type = state.def.name

    o.actionState = state
    o.maxTime = state.def.time

    return o
end

return PerformActionAction