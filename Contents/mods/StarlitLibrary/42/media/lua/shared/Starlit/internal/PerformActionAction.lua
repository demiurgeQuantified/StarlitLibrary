local ActionState = require("Starlit/action/ActionState")

---@class starlit.PerformActionAction : ISBaseTimedAction
---@field state starlit.ActionState
local PerformActionAction = ISBaseTimedAction:derive("starlit.PerformActionAction")

PerformActionAction.isValid = function(self)
    return ActionState.isActionStateStillValid(self.state)
end

PerformActionAction.update = function(self)
    self:setItemsJobDelta(self:getJobDelta())

    self.state.def.update(self.state)
    ISBaseTimedAction.update(self)
end

PerformActionAction.waitToStart = function(self)
    if not self.state.def.faceObject then
        return false
    end
    self.character:faceThisObject(self.state.objects[self.state.def.faceObject])
    return self.character:shouldBeTurning()
end

---@param delta number
PerformActionAction.setItemsJobDelta = function(self, delta)
    for _, item in pairs(self.state.items) do
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
    for _, item in pairs(self.state.items) do
        if type(item) == "table" then
            for i = 1, #item do
                ---@diagnostic disable-next-line: param-type-mismatch
                item[i]:setJobType(name)
            end
        else
            ---@diagnostic disable-next-line: param-type-mismatch
            item:setJobType(name)
        end
    end
end

PerformActionAction.cleanup = function(self)
    self:setItemsJobDelta(0)
    self:setItemsJobType(nil)
end

PerformActionAction.stop = function(self)
    self.state.def.stop(self.state)
    self:cleanup()
    ISBaseTimedAction.stop(self)
end

PerformActionAction.perform = function(self)
    self.state.def.complete(self.state)
    self:cleanup()
    ISBaseTimedAction.perform(self)
end

PerformActionAction.start = function(self)
    if not ActionState.isActionStateStillValid(self.state) then
        -- TODO: in some situations we may want to build a new state instead of cancelling
        -- e.g. if i queued the action for later, even if i lost the item i was going to use for it
        -- i may still have a valid one
        self:forceCancel()
        return
    end

    self:setItemsJobDelta(0)
    self:setItemsJobType(self.state.def.name)

    if self.state.def.animation then
        self:setActionAnim(self.state.def.animation)
    end

    self.state.def.start(self.state)

    ISBaseTimedAction.start(self)
end

---@param state starlit.ActionState
---@return starlit.PerformActionAction action
PerformActionAction.new = function(state)
    local o = ISBaseTimedAction:new(state.character)
    setmetatable(o, PerformActionAction) ---@cast o starlit.PerformActionAction
    o.Type = state.def.name

    o.state = state

    o.maxTime = state.def.time
    o.stopOnAim = state.def.stopOnAim
    o.stopOnWalk = state.def.stopOnWalk
    o.stopOnRun = state.def.stopOnRun

    if state.character:isTimedActionInstant() then
        o.maxTime = 0
    end

    return o
end

return PerformActionAction