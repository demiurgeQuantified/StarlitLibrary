local TransferItemTypeAction = require "Starlit/client/timedActions/TransferItemTypeAction"

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
---@param predicate ItemContainer_Predicate? Optional item evaluation function.
TimedActionUtils.transferFirstType = function(character, type, predicate)
    ISTimedActionQueue.add(
        TransferItemTypeAction.new(character, type, predicate))
end

---Queues actions to transfer an item to the character's inventory and equip it.
---Actions will be skipped as appropriate if the item is already in the player's inventory or already equipped in that slot.
---@param character IsoGameCharacter The character
---@param item InventoryItem The item to equip
---@param slot? "primary"|"secondary" Which slot to equip it in. If not passed, primary is assumed
TimedActionUtils.transferAndEquip = function(character, item, slot)
    slot = slot or "primary"
    local needEquip
    if slot == "primary" then
        needEquip = character:getPrimaryHandItem() ~= item
    else
        needEquip = character:getSecondaryHandItem() ~= item
    end
    if not needEquip then return end

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
end

---Finds an item and queues actions to transfer it to the character's inventory and equip it.
---Actions will be skipped as appropriate if a passing item is already in the player's inventory or already equipped in that slot.
---No actions are queued if no item was found.
---@param character IsoGameCharacter The character
---@param eval ItemContainer_Predicate Item evaluation function
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

    ISTimedActionQueue.add(ISWearClothing:new(character, item, 50))
end

---Finds an item and queues actions to transfer it to the character's inventory and wear it.
---Actions will be skipped as appropriate if the item is already in the player's inventory or already worn.
---No actions are queued if no item was found.
---@param character IsoGameCharacter The character
---@param eval ItemContainer_Predicate Item evaluation function. It must not return true for items that cannot be worn.
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

    ISTimedActionQueue.add(ISWearClothing:new(character, item, 50))
    return true
end

return TimedActionUtils