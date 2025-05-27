local TransferItemAction = require "Starlit/timedActions/TransferItemAction"

---Module for timed action helper functions
local TimedActionUtils = {}

---Queues an action to transfer an item to the characters's inventory.
---Does nothing if the item is already in the character's inventory.
---@param character IsoGameCharacter The character
---@param item InventoryItem The item to transfer
TimedActionUtils.transfer = function(character, item)
    local inventory = character:getInventory()
    if not inventory:contains(item) then
        ISTimedActionQueue.add(
            ISInventoryTransferAction:new(
                character, item,
                item:getContainer(), inventory))
    end
end

---Queues an action to transfer the first item of a type to the character's inventory.
---This differs from regular transfer as the item is picked at the start of the action.
---This prevents issues where multiple queued actions target the same item, causing later actions
---to fail even though there are still valid items in the player's inventory.
---@param character IsoGameCharacter The character.
---@param type string The item type to transfer.
---@param predicate? umbrella.ItemContainer_Predicate Optional item evaluation function.
---@param predicateArg? any Optional predicate argument.
---@deprecated Replaced by TimedActionUtils.transferFirstValid
TimedActionUtils.transferFirstType = function(character, type, predicate, predicateArg)
    TimedActionUtils.transferFirstValid(character, type, predicate, predicateArg)
end

---Queues an action to transfer the first item matching the criteria from the characters's containers into their main inventory.
---This differs from regular transfer as the item is picked at the start of the action.
---This prevents issues where multiple queued actions target the same item, causing later actions
---to fail even though there are still valid items in the player's inventory.
---@param character IsoGameCharacter The character.
---@param type? string The item type to transfer. If nil does not check item type.
---@param predicate? umbrella.ItemContainer_Predicate Optional item evaluation function.
---@param predicateArg? any Optional predicate argument.
TimedActionUtils.transferFirstValid = function(character, type, predicate, predicateArg)
    assert(type or predicate, "No item predicate or type passed to TimedActionUtils.transferFirstValid")
    ISTimedActionQueue.add(
        TransferItemAction.new(
            character, type, predicate, predicateArg, 1))
end

---Queues an action to transfer items matching the criteria from the character's containers into their main inventory.
---This differs from regular transfer as the item is picked at the start of the action.
---This prevents issues where multiple queued actions target the same item, causing later actions
---to fail even though there are still valid items in the player's inventory.
---@param character IsoGameCharacter The character.
---@param type? string The item type to transfer. If nil does not check item type.
---@param predicate? umbrella.ItemContainer_Predicate Optional item evaluation function.
---@param predicateArg? any Optional predicate argument.
---@param amount integer Amount of items to transfer.
TimedActionUtils.transferSomeValid = function(character, type, predicate, predicateArg, amount)
    assert(type or predicate, "No item predicate or type passed to TimedActionUtils.transferFirstValid")
    ISTimedActionQueue.add(
        TransferItemAction.new(
            character, type, predicate, predicateArg, amount))
end

---Queues actions to transfer an item to the character's inventory and equip it.
---Actions will be skipped as appropriate if the item is already in the player's inventory or already equipped in that slot.
---@param character IsoGameCharacter The character.
---@param item InventoryItem | nil The item to equip. If nil, the item already equipped in the slot will be unequipped, if any.
---@param slot? "primary"|"secondary" Which slot to equip it in. If not passed, primary is assumed.
TimedActionUtils.transferAndEquip = function(character, item, slot)
    slot = slot or "primary"
    local needEquip
    if slot == "primary" then
        needEquip = character:getPrimaryHandItem() ~= item
    else
        needEquip = character:getSecondaryHandItem() ~= item
    end
    if not needEquip then return end

    if item then
        local inventory = character:getInventory()
        if not inventory:contains(item) then
            ISTimedActionQueue.add(
                ISInventoryTransferAction:new(
                    character, item,
                    item:getContainer(), inventory))
        end

        ISTimedActionQueue.add(
            ISEquipWeaponAction:new(
                character, item, 50, slot == "primary"))
    else
        ISTimedActionQueue.add(
            ISUnequipAction:new(
                character,
                slot == "primary" and character:getPrimaryHandItem() or character:getSecondaryHandItem(),
                50
            )
        )
    end
end

---Finds an item and queues actions to transfer it to the character's inventory and equip it.
---Actions will be skipped as appropriate if a passing item is already in the player's inventory or already equipped in that slot.
---No actions are queued if no item was found.
---@param character IsoGameCharacter The character
---@param eval umbrella.ItemContainer_Predicate Item evaluation function
---@param slot? "primary"|"secondary" Which slot to equip it in. If not passed, primary is assumed
---@return boolean found Whether an item was found. This doesn't necessarily mean the actions will go through, as the item could already be equipped.
TimedActionUtils.transferAndEquipFirstEval = function(character, eval, slot)
    slot = slot or "primary"
    local equippedItem
    if slot == "primary" then
        equippedItem = character:getPrimaryHandItem()
    else
        equippedItem = character:getSecondaryHandItem()
    end
    if equippedItem and eval(equippedItem) then return true end

    local inventory = character:getInventory()
    local item = inventory:getFirstEvalRecurse(eval)
    if not item then return false end

    if not inventory:contains(item) then
        ISTimedActionQueue.add(
            ISInventoryTransferAction:new(
                character, item,
                item:getContainer(), inventory))
    end

    ISTimedActionQueue.add(
        ISEquipWeaponAction:new(
            character, item, 50, slot == "primary"))
    return true
end

---Queues actions to transfer an item to the character's inventory and wear it.
---Actions will be skipped as appropriate if the item is already in the player's inventory or already worn.
---@param character IsoGameCharacter The character
---@param item Clothing The item to equip
TimedActionUtils.transferAndWear = function(character, item)
    if character:getWornItems():contains(item) then return end

    local inventory = character:getInventory()
    if not inventory:contains(item) then
        ISTimedActionQueue.add(
            ISInventoryTransferAction:new(
                character, item,
                item:getContainer(), inventory))
    end

    ISTimedActionQueue.add(
        ISWearClothing:new(character, item))
end

---Finds an item and queues actions to transfer it to the character's inventory and wear it.
---Actions will be skipped as appropriate if the item is already in the player's inventory or already worn.
---No actions are queued if no item was found.
---@param character IsoGameCharacter The character
---@param eval umbrella.ItemContainer_Predicate Item evaluation function. It must not return true for items that cannot be worn.
---@return boolean found Whether an item was found. This doesn't necessarily mean the actions will go through, as the item could already be equipped.
TimedActionUtils.transferAndWearFirstEval = function(character, eval)
    local wornItems = character:getWornItems()
    for i = 0, wornItems:size()-1 do
        if eval(wornItems:get(i):getItem()) then
            return true
        end
    end

    local inventory = character:getInventory()
    local item = inventory:getFirstEvalRecurse(eval)
    if not item then return false end

    if not inventory:contains(item) then
        ISTimedActionQueue.add(
            ISInventoryTransferAction:new(
                character, item,
                item:getContainer(), inventory))
    end

    ISTimedActionQueue.add(
        ISWearClothing:new(character, item))
    return true
end

---Queues actions to unequip an item if it is equipped or worn. Does nothing if the item is not equipped or worn.
---@param character IsoGameCharacter The character.
---@param item InventoryItem The item to unequip.
TimedActionUtils.unequip = function(character, item)
    if not item:isEquipped() then return end
    ISTimedActionQueue.add(
        ISUnequipAction:new(
            character, item, 50))
end

return TimedActionUtils