local TimedActionUtils = require("Starlit/timedActions/TimedActionUtils")
local PerformActionAction = require("Starlit/internal/PerformActionAction")

---@class starlit.PrepareActionAction : ISBaseTimedAction
---@field state starlit.ActionState
local PrepareActionAction = ISBaseTimedAction:derive("starlit.PrepareActionAction")

PrepareActionAction.isValid = function(self)
    return true
end

---@param slot "primary"|"secondary"
---@param model string | nil
PrepareActionAction.setHandModel = function(self, slot, model)
    if not model then
        -- nil means we don't care what's in this hand
        return
    end

    if model == "EMPTY" then
        -- EMPTY removes any equipped item from the hand
        local equippedItem
        if slot == "primary" then
            equippedItem = self.character:getPrimaryHandItem()
        else
            equippedItem = self.character:getSecondaryHandItem()
            if equippedItem == self.character:getPrimaryHandItem() then
                -- we don't unequip anything if the secondary item is being two-handed (we consider this a primary item)
                return
            end
        end

        if not equippedItem then
            return
        end

        TimedActionUtils.unequip(
            self.character,
            equippedItem
        )
        return
    end

    local item = self.state.items[model]
    if item then
        -- if it's an item identifier, equip that item
        if type(item) == "table" then
            item = item[1]
        end
        TimedActionUtils.transferAndEquip(self.character, item, slot)
    else
        -- otherwise set as string model
        -- we need to get the existing model in the other slot to avoid overriding it with nil
        if slot == "primary" then
            self:setOverrideHandModelsString(model, self.action:getSecondaryHandMdl())
        else
            self:setOverrideHandModelsString(self.action:getPrimaryHandMdl(), model)
        end
    end
end

PrepareActionAction.perform = function(self)
    self:beginAddingActions()

    if self.state.def.walkToObject then
        local object = self.state.objects[self.state.def.walkToObject]

        local square
        if instanceof(object, "IsoDoor") or instanceof(object, "IsoWindow") then
            -- doors and windows use a different square selection algorithm
            square = AdjacentFreeTileFinder.FindWindowOrDoor(
                object:getSquare(), object, self.character
            )
        else
            square = AdjacentFreeTileFinder.Find(
                object:getSquare(), self.character
            )
        end

        if not square then
            self:forceCancel()
            return
        end

        ISTimedActionQueue.add(
            ISWalkToTimedAction:new(self.character, square)
        )
    end

    -- TODO: support moving items into main inventory

    self:setHandModel("primary", self.state.def.primaryItem)
    self:setHandModel("secondary", self.state.def.secondaryItem)

    ISTimedActionQueue.add(PerformActionAction.new(self.state))

    self:endAddingActions()
    ISBaseTimedAction.perform(self)
end

---@param state starlit.ActionState
---@return starlit.PrepareActionAction
PrepareActionAction.new = function(state)
    local o = ISBaseTimedAction:new(state.character)

    setmetatable(o, PrepareActionAction)
    ---@cast o starlit.PrepareActionAction

    o.state = state
    o.maxTime = 0

    return o
end

return PrepareActionAction