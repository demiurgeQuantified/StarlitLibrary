local TimedActionUtils = require("Starlit/timedActions/TimedActionUtils")
local PerformActionAction = require("Starlit/internal/PerformActionAction")

---@class starlit.PrepareActionAction : ISBaseTimedAction
---@field actionState starlit.ActionState
local PrepareActionAction = ISBaseTimedAction:derive("starlit.PrepareActionAction")

PrepareActionAction.isValid = function(self)
    return true
end

PrepareActionAction.perform = function (self)
    self:beginAddingActions()

    local prop1 = type(self.actionState.items.prop1) == "table" and self.actionState.items.prop1[1] or self.actionState.items.prop1
    local prop2 = type(self.actionState.items.prop2) == "table" and self.actionState.items.prop2[1] or self.actionState.items.prop2
    TimedActionUtils.transferAndEquip(self.character, prop1, "primary")
    TimedActionUtils.transferAndEquip(self.character, prop2, "secondary")

    ISTimedActionQueue.add(PerformActionAction.new(self.actionState))

    self:endAddingActions()
    ISBaseTimedAction.perform(self)
end

---@param state starlit.ActionState
---@return starlit.PrepareActionAction
PrepareActionAction.new = function(state)
    local o = ISBaseTimedAction:new(state.character)

    setmetatable(o, PrepareActionAction)
    ---@cast o starlit.PrepareActionAction

    o.actionState = state
    o.maxTime = 0

    return o
end

return PrepareActionAction