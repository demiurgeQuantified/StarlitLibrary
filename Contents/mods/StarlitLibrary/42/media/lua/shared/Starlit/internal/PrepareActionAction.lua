local TimedActionUtils = require("Starlit/timedActions/TimedActionUtils")
local PerformActionAction = require("Starlit/internal/PerformActionAction")


---@param state starlit.ActionState
---@param slot "primary" | "secondary"
---@return InventoryItem | nil
---@nodiscard
local function getDesiredItemInSlot(state, slot)
    local itemName = slot == "primary" and state.action.primaryItem or state.action.secondaryItem
    local item = state.items[itemName]
    if not item then
        return nil
    end
    if type(item) == "table" then
        ---@cast item InventoryItem[]
        return item[1]
    end
    return item
end


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
            -- the item will be moved into the correct slot by the action to equip it, no need to do anything
            if equippedItem == getDesiredItemInSlot(self.state, "secondary") then
                return
            end
        else
            equippedItem = self.character:getSecondaryHandItem()
            if equippedItem == self.character:getPrimaryHandItem() then
                -- we don't unequip anything if the secondary item is being two-handed (we consider this a primary item)
                return
            end
            -- the item will be moved into the correct slot by the action to equip it, no need to do anything
            if equippedItem == getDesiredItemInSlot(self.state, "primary") then
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

    local item = getDesiredItemInSlot(self.state, slot)
    if item then
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

    if self.state.action.walkToObject then
        local object = self.state.objects[self.state.action.walkToObject]

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

    for name, itemDef in pairs(self.state.action.requiredItems) do
        if itemDef.mainInventory then
            local items = self.state.items[name]
            if type(items) == "table" then
                ---@cast items InventoryItem[]
                for i = 1, #items do
                    TimedActionUtils.transfer(
                        self.character,
                        items[i]
                    )
                end
            else
                TimedActionUtils.transfer(
                    self.character,
                    items
                )
            end
        end
    end

    self:setHandModel("primary", self.state.action.primaryItem)
    self:setHandModel("secondary", self.state.action.secondaryItem)

    ISTimedActionQueue.add(PerformActionAction.new(self.state))

    self:endAddingActions()
    ISBaseTimedAction.perform(self)
end


---@param state starlit.ActionState
---@return starlit.PrepareActionAction
---@nodiscard
PrepareActionAction.new = function(state)
    local o = ISBaseTimedAction:new(state.character)

    setmetatable(o, PrepareActionAction)
    ---@cast o starlit.PrepareActionAction

    o.state = state
    o.maxTime = 0

    return o
end


return PrepareActionAction