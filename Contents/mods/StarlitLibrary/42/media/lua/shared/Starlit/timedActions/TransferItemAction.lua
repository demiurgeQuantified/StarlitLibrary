local CACHE_ARRAY_LIST = ArrayList.new()

---@class TransferItemTypeAction : ISBaseTimedAction
---@field character IsoGameCharacter
---@field itemType string?
---@field predicate ItemContainer_Predicate?
---@field arg any
---@field amount integer
local TransferItemAction = ISBaseTimedAction:derive("StarlitTransferItemTypeAction")
TransferItemAction.__index = TransferItemAction

TransferItemAction.perform = function(self)
    local inventory = self.character:getInventory()

    if self.amount == 1 then
        local item
        if self.itemType then
            if self.predicate then
                item = inventory:getFirstTypeEvalArgRecurse(self.itemType, self.predicate, self.arg)
            else
                item = inventory:getFirstTypeRecurse(self.itemType)
            end
        else
            item = inventory:getFirstEvalArgRecurse(self.predicate, self.arg)
        end

        ISTimedActionQueue.addAfter(
            self,
            ISInventoryTransferAction:new(
                self.character, item,
                item:getContainer(), inventory))
    else
        ---@type ArrayList
        local items
        if self.itemType then
            if self.predicate then
                items = inventory:getSomeTypeEvalArgRecurse(
                    self.itemType, self.predicate, self.arg, self.amount, CACHE_ARRAY_LIST)
            else
                items = inventory:getSomeType(
                    self.itemType, self.amount, CACHE_ARRAY_LIST)
            end
        else
            items = inventory:getSomeEvalArgRecurse(
                self.predicate, self.arg, self.amount, CACHE_ARRAY_LIST)
        end

        for i = 0, self.amount - 1 do
            local item = items:get(i) --[[@as InventoryItem]]

            ISTimedActionQueue.addAfter(
                self,
                ISInventoryTransferAction:new(
                    self.character, item,
                    item:getContainer(), inventory))
        end

        CACHE_ARRAY_LIST:clear()
    end

    ISBaseTimedAction.perform(self)
end

TransferItemAction.isValidStart = function(self)
    local inventory = self.character:getInventory()
    if self.amount == 1 then -- these functions are cheaper
        if self.itemType then
            if self.predicate then
                return inventory:containsTypeEvalArgRecurse(self.itemType, self.predicate, self.arg)
            else
                return inventory:containsTypeRecurse(self.itemType)
            end
        else
            return inventory:containsEvalArgRecurse(self.predicate, self.arg)
        end
    else
        if self.itemType then
            if self.predicate then
                return inventory:getSomeTypeEvalArgRecurse(
                    self.itemType, self.predicate, self.arg, self.amount, CACHE_ARRAY_LIST):size() >= self.amount
            else
                return inventory:getSomeType(
                    self.itemType, self.amount, CACHE_ARRAY_LIST):size() >= self.amount
            end
        else
            return inventory:getSomeEvalArgRecurse(
                self.predicate, self.arg, self.amount, CACHE_ARRAY_LIST):size() >= self.amount
        end
        CACHE_ARRAY_LIST:clear()
    end
end

TransferItemAction.isValid = function(self)
    return true
end

---@param character IsoGameCharacter
---@param type string?
---@param predicate ItemContainer_Predicate?
---@param arg any
---@param amount integer
---@return TransferItemTypeAction
---@nodiscard
TransferItemAction.new = function(character, type, predicate, arg, amount)
    local o = ISBaseTimedAction:new(character) --[[@as TransferItemTypeAction]]
    setmetatable(o, TransferItemAction)

    o.itemType = type
    o.predicate = predicate
    o.arg = arg
    o.amount = amount

    o.maxTime = 0

    return o
end

return TransferItemAction