local ActionState = require("Starlit/action/ActionState")

---@class starlit.PerformActionAction : ISBaseTimedAction
---@field state starlit.ActionState
local PerformActionAction = ISBaseTimedAction:derive("starlit.PerformActionAction")

PerformActionAction.isValid = function(self)
    return ActionState.stillValid(self.state)
end

PerformActionAction.update = function(self)
    self:setItemsJobDelta(self:getJobDelta())

    self.state.action.update(self.state)
    ISBaseTimedAction.update(self)
end

PerformActionAction.waitToStart = function(self)
    if not self.state.action.faceObject then
        return false
    end
    self.character:faceThisObject(self.state.objects[self.state.action.faceObject])
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
    for variable, _ in pairs(self.state.action.animationVariables) do
        self.state.character:clearVariable(variable)
    end
end

PerformActionAction.stop = function(self)
    self.state.action.abort(self.state)
    self:cleanup()
    ISBaseTimedAction.stop(self)
end

PerformActionAction.perform = function(self)
    self.state.action.complete(self.state)
    self:cleanup()

    for name, requirement in pairs(self.state.action.requiredItems) do
        if requirement.consumed then
            local items = self.state.items[name]
            if requirement.uses > 0 then
                ---@cast items InventoryItem[]
                for i = 1, #items do
                    items[i]:Use()
                end
            elseif requirement.count > 1 then
                ---@cast items InventoryItem[]
                local inventory = self.state.character:getInventory()
                for i = 1, #items do
                    inventory:Remove(items[i])
                end
            else
                ---@cast items InventoryItem
                self.state.character:getInventory():Remove(items)
            end
        end
    end

    ISBaseTimedAction.perform(self)
end

PerformActionAction.start = function(self)
    if not ActionState.stillValid(self.state) then
        -- TODO: in some situations we may want to build a new state instead of cancelling
        -- e.g. if i queued the action for later, even if i lost the item i was going to use for it
        -- i may still have a valid one
        self:forceCancel()
        return
    end

    self:setItemsJobDelta(0)
    self:setItemsJobType(self.state.action.name)

    if self.state.action.animation then
        self:setActionAnim(self.state.action.animation)
    end

    for variable, value in pairs(self.state.action.animationVariables) do
        self.state.character:setVariable(variable, value)
    end

    self.state.action.start(self.state)

    ISBaseTimedAction.start(self)
end

---@param state starlit.ActionState
---@return starlit.PerformActionAction action
PerformActionAction.new = function(state)
    local o = ISBaseTimedAction:new(state.character)
    setmetatable(o, PerformActionAction) ---@cast o starlit.PerformActionAction
    o.Type = state.action.name

    o.state = state

    o.maxTime = state.action.time
    o.stopOnAim = state.action.stopOnAim
    o.stopOnWalk = state.action.stopOnWalk
    o.stopOnRun = state.action.stopOnRun

    if state.character:isTimedActionInstant() then
        o.maxTime = 0
    end

    return o
end

return PerformActionAction