TimedActionUtils
================
::

   local TimedActionUtils = require("Starlit/timedActions/TimedActionUtils")

The TimedActionUtils module provides utilities for creating and working with timed actions. Currently it focuses primarily on handling prerequisite timed actions (e.g. equip item used in next timed action).

.. note::
   This module is for working with Vanilla timed actions. It is intended to mostly be replaced by the Action framework in v42-1.5.0.

.. lua:module:: TimedActionUtils

Functions
---------
.. lua:function:: transfer(character: IsoGameCharacter, item: InventoryItem)

   Queues an action to transfer an item to the characters's inventory.
   Does nothing if the item is already in the character's inventory.

   :param IsoGameCharacter character: The character.
   :param InventoryItem item: The item to transfer.

.. lua:function:: transferFirstValid(character: IsoGameCharacter, type: string | nil, predicate: umbrella.ItemContainer_Predicate | nil, predicateArg: any)

   Queues an action to transfer the first item matching the criteria from the characters's containers into their main inventory.
   This differs from regular transfer as the item is picked at the start of the action.
   This prevents issues where multiple queued actions target the same item, causing later actions
   to fail even though there are still valid items in the player's inventory.

   :param character IsoGameCharacter: The character.
   :param string | nil type: The item type to transfer. If nil does not check item type.
   :param umbrella.ItemContainer_Predicate | nil predicate: Optional item evaluation function.
   :param any predicateArg: Optional predicate argument.

.. lua:function:: transferSomeValid(character: IsoGameCharacter, type: string | nil, predicate: umbrella.ItemContainer_Predicate | nil, predicateArg: any, amount: integer)

   Queues an action to transfer items matching the criteria from the character's containers into their main inventory.
   This differs from regular transfer as the item is picked at the start of the action.
   This prevents issues where multiple queued actions target the same item, causing later actions
   to fail even though there are still valid items in the player's inventory.

   :param IsoGameCharacter character: The character.
   :param string | nil type: The item type to transfer. If nil does not check item type.
   :param umbrella.ItemContainer_Predicate | nil predicate: Optional item evaluation function.
   :param any predicateArg: Optional predicate argument.
   :param integer amount: Amount of items to transfer.

.. lua:function:: transferAndEquip(character: IsoGameCharacter, item: InventoryItem | nil, slot: "primary" | "secondary" | "nil")

   Queues actions to transfer an item to the character's inventory and equip it.
   Actions will be skipped as appropriate if the item is already in the player's inventory or already equipped in that slot.
   
   :param IsoGameCharacter character: The character.
   :param InventoryItem | nil item: The item to equip. If nil, the item already equipped in the slot will be unequipped, if any.
   :param "primary" \| "secondary" | nil slot: Which slot to equip it in. If not passed, primary is assumed.

.. lua:function:: transferAndEquipFirstEval(character: IsoGameCharacter, eval: umbrella.ItemContainer_Predicate, slot: "primary" \| "secondary" | nil) -> found: boolean

   Finds an item and queues actions to transfer it to the character's inventory and equip it.
   Actions will be skipped as appropriate if a passing item is already in the player's inventory or already equipped in that slot.
   No actions are queued if no item was found.
   
   :param IsoGameCharacter character: The character
   :param umbrella.ItemContainer_Predicate eval: Item evaluation function
   :param "primary" \| "secondary" | nil slot: Which slot to equip it in. If not passed, primary is assumed
   :return boolean found: Whether an item was found. This doesn't necessarily mean the actions will go through, as the item could already be equipped.

.. lua:function:: transferAndWear(character: IsoGameCharacter, item: Clothing)

   Queues actions to transfer an item to the character's inventory and wear it.
   Actions will be skipped as appropriate if the item is already in the player's inventory or already worn.

   :param IsoGameCharacter character: The character.
   :param Clothing item: The item to equip.

.. lua:function:: transferAndWearFirstEval(character: IsoGameCharacter, eval: umbrella.ItemContainer_Predicate) -> found: boolean

   Finds an item and queues actions to transfer it to the character's inventory and wear it.
   Actions will be skipped as appropriate if the item is already in the player's inventory or already worn.
   No actions are queued if no item was found.

   :param IsoGameCharacter character: The character
   :param umbrella.ItemContainer_Predicate eval: Item evaluation function. It must not return true for items that cannot be worn.
   :return boolean found: Whether an item was found. This doesn't necessarily mean the actions will go through, as the item could already be equipped.

.. lua:function:: unequip(character: IsoGameCharacter, item: InventoryItem)
   
   Queues actions to unequip an item if it is equipped or worn. Does nothing if the item is not equipped or worn.
   
   :param IsoGameCharacter character: The character.
   :param InventoryItem item: The item to unequip.

.. deprecated::
   Replaced by :lua:func:`TimedActionUtils.transferFirstValid`, which incorporates the same functionality and more.
.. lua:function:: transferFirstType(character: IsoGameCharacter, type: string, predicate: umbrella.ItemContainer_Predicate | nil, predicateArg: any)

   Queues an action to transfer the first item of a type to the character's inventory.
   This differs from regular transfer as the item is picked at the start of the action.
   This prevents issues where multiple queued actions target the same item, causing later actions
   to fail even though there are still valid items in the player's inventory.

   :param IsoGameCharacter character: The character.
   :param string type: The item type to transfer.
   :param umbrella.ItemContainer_Predicate | nil predicate: Optional item evaluation function.
   :param predicateArg any: Optional predicate argument.
