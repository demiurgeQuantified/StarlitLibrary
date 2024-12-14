---@class TransferItemTypeAction : ISBaseTimedAction
---@field character IsoGameCharacter
---@field itemType string?
---@field predicate ItemContainer_Predicate?
---@field arg any
local TransferItemAction = ISBaseTimedAction:derive("StarlitTransferItemTypeAction")
TransferItemAction.__index = TransferItemAction

TransferItemAction.perform = function(self)
    local inventory = self.character:getInventory()

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

    ISBaseTimedAction.perform(self)
end

TransferItemAction.isValidStart = function(self)
    local inventory = self.character:getInventory()
    if self.itemType then
        if self.predicate then
            return inventory:containsTypeEvalArgRecurse(self.itemType, self.predicate, self.arg)
        else
            return inventory:containsTypeRecurse(self.itemType)
        end
    else
        return inventory:containsEvalArgRecurse(self.predicate, self.arg)
    end
end

TransferItemAction.isValid = function(self)
    return true
end

---@param character IsoGameCharacter
---@param type string?
---@param predicate ItemContainer_Predicate?
---@param arg any
---@return TransferItemTypeAction
TransferItemAction.new = function(character, type, predicate, arg)
    local o = ISBaseTimedAction:new(character) --[[@as TransferItemTypeAction]]
    setmetatable(o, TransferItemAction)

    o.itemType = type
    o.predicate = predicate
    o.arg = arg

    o.maxTime = 0

    return o
end

return TransferItemAction