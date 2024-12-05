---@class TransferItemTypeAction : ISBaseTimedAction
---@field character IsoGameCharacter
---@field itemType string
---@field predicate ItemContainer_Predicate?
local TransferItemTypeAction = ISBaseTimedAction:derive("StarlitTransferItemTypeAction")
TransferItemTypeAction.__index = TransferItemTypeAction

TransferItemTypeAction.perform = function(self)
    local inventory = self.character:getInventory()

    local item
    if self.predicate then
        item = inventory:getFirstTypeEvalRecurse(self.itemType, self.predicate)
    else
        item = inventory:getFirstTypeRecurse(self.itemType)
    end

    ISTimedActionQueue.addAfter(
        self,
        ISInventoryTransferAction:new(
            self.character, item,
            item:getContainer(), inventory))

    ISBaseTimedAction.perform(self)
end

TransferItemTypeAction.isValidStart = function(self)
    local inventory = self.character:getInventory()
    if self.predicate then
        return inventory:containsTypeEvalRecurse(self.itemType, self.predicate)
    else
        return inventory:containsTypeRecurse(self.itemType)
    end
end

TransferItemTypeAction.isValid = function(self)
    return true
end

---@param character IsoGameCharacter
---@param type string
---@param predicate ItemContainer_Predicate?
---@return TransferItemTypeAction
TransferItemTypeAction.new = function(character, type, predicate)
    local o = ISBaseTimedAction:new(character) --[[@as TransferItemTypeAction]]
    setmetatable(o, TransferItemTypeAction)

    o.itemType = type
    o.predicate = predicate

    o.maxTime = 0

    return o
end

return TransferItemTypeAction