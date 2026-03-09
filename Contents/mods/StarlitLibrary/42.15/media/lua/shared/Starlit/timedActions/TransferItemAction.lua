local CACHE_ARRAY_LIST = ArrayList.new--[[@<InventoryItem>]]()


---@class TransferItemTypeAction : ISBaseTimedAction
---@field character IsoGameCharacter
---@field itemType string?
---@field predicate (fun(item:InventoryItem):boolean)?
---@field arg any
---@field amount integer
local TransferItemAction = ISBaseTimedAction:derive("StarlitTransferItemTypeAction")
TransferItemAction.__index = TransferItemAction


function TransferItemAction:perform()
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
            assert(self.predicate ~= nil)
            item = inventory:getFirstEvalArgRecurse(self.predicate, self.arg)
        end

        ISTimedActionQueue.addAfter(
            self,
            ISInventoryTransferAction:new(
                self.character,
                item,
                item:getContainer(),
                inventory
            )
        )
    else
        ---@type ArrayList
        local items
        if self.itemType then
            if self.predicate then
                items = inventory:getSomeTypeEvalArgRecurse(
                    self.itemType,
                    self.predicate,
                    self.arg,
                    self.amount,
                    CACHE_ARRAY_LIST
                )
            else
                items = inventory:getSomeType(
                    self.itemType,
                    self.amount,
                    CACHE_ARRAY_LIST
                )
            end
        else
            assert(self.predicate ~= nil)
            items = inventory:getSomeEvalArgRecurse(
                self.predicate,
                self.arg,
                self.amount,
                CACHE_ARRAY_LIST
            )
        end

        for i = 0, self.amount - 1 do
            local item = items:get(i) --[[@as InventoryItem]]

            ISTimedActionQueue.addAfter(
                self,
                ISInventoryTransferAction:new(
                    self.character,
                    item,
                    item:getContainer(),
                    inventory
                )
            )
        end

        CACHE_ARRAY_LIST:clear()
    end

    ISBaseTimedAction.perform(self)
end


function TransferItemAction:isValidStart()
    local inventory = self.character:getInventory()
    if self.amount == 1 then -- these functions are cheaper
        if self.itemType then
            if self.predicate then
                return inventory:containsTypeEvalArgRecurse(self.itemType, self.predicate, self.arg)
            else
                return inventory:containsTypeRecurse(self.itemType)
            end
        else
            assert(self.predicate ~= nil)
            return inventory:containsEvalArgRecurse(self.predicate, self.arg)
        end
    else
        local result

        if self.itemType then
            if self.predicate then
                result = inventory:getSomeTypeEvalArgRecurse(
                        self.itemType,
                        self.predicate,
                        self.arg,
                        self.amount,
                        CACHE_ARRAY_LIST
                    ):size() >= self.amount
            else
                result = inventory:getSomeType(
                        self.itemType,
                        self.amount,
                        CACHE_ARRAY_LIST
                    ):size() >= self.amount
            end
        else
            assert(self.predicate ~= nil)
            result = inventory:getSomeEvalArgRecurse(
                    self.predicate,
                    self.arg,
                    self.amount,
                    CACHE_ARRAY_LIST
                ):size() >= self.amount
        end

        CACHE_ARRAY_LIST:clear()

        return result
    end
end


function TransferItemAction:isValid()
    return true
end


---@param character IsoGameCharacter
---@param type string?
---@param predicate (fun(item:InventoryItem):boolean)?
---@param arg any
---@param amount integer
---@return TransferItemTypeAction
---@nodiscard
function TransferItemAction:new(character, type, predicate, arg, amount)
    local o = ISBaseTimedAction.new(self, character) --[[@as TransferItemTypeAction]]

    o.itemType = type
    o.predicate = predicate
    o.arg = arg
    o.amount = amount

    o.maxTime = 0

    return o
end


_G[TransferItemAction.Type] = TransferItemAction


return TransferItemAction