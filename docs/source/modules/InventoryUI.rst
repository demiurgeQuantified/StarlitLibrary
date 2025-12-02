InventoryUI
===========
::

   local InventoryUI = require("Starlit/client/ui/InventoryUI")

The InventoryUI module contains utilities related to the character inventory UI. Currently it only contains utilities for item tooltips.

.. lua:automodule:: Starlit.client.ui.InventoryUI
   :members:
   :recursive:

Examples
--------
A basic example of using the ``OnFillItemTooltip`` event to populate a specific item's tooltip:
::
    
   -- Require the InventoryUI module so we can use it.
   local InventoryUI = require("Starlit/client/ui/InventoryUI")


   -- Create the event listener.
   -- If your IDE supports LuaCATS annotations, the following line tells it the function is an event listener.
   ---@type Starlit.InventoryUI.Callback_OnFillItemTooltip
   local function addAppleTooltip(tooltip, layout, item)
       -- Only run our code if the item is an apple
       if item:getFullType() ~= "Base.Apple" then
          return
       end

       -- Adds the text 'Apple.' to every apple's tooltip.
       InventoryUI.addTooltipLabel(layout, "Apple.")

       -- Adds the key-value pair "Grown at: Sweet Apple Acres" to every apple's tooltip.
       InventoryUI.addTooltipKeyValue(layout, "Grown at:", "Sweet Apple Acres")

       -- Adds a half-full progress bar for sweetness to every apple's tooltip.
       InventoryUI.addTooltipBar(layout, "Sweetness:", 0.5)

       -- Adds a bites taken counter to every apple's tooltip, with the value 1.
       InventoryUI.addTooltipInteger(layout, "Bites taken:", 1, false)

       -- Finds and returns the Vanilla tooltip element showing the item's encumbrance.
       local encumbrance = InventoryUI.getTooltipElementByLabel(layout, getText("Tooltip_item_Weight") .. ":")
       -- If encumbrance is nil, then it's already been removed by another mod.
       if encumbrance then
           -- Removes the encumbrance element.
           InventoryUI.removeTooltipElement(layout, encumbrance)
       end
   end

   -- Adds the event listener to the event, so that it will be called when the event is triggered.
   InventoryUI.onFillItemTooltip:addListener(addAppleTooltip)

Using the ``preRenderItems`` event to dynamically change the name of an item:
::
   
    local InventoryUI = require("Starlit/client/ui/InventoryUI")

    ---@type Starlit.InventoryUI.Callback_preDisplayItems
    local function setAppleName(items, player)
        -- we only change the name of apples if the player has the trait
        if not player:hasTrait("AppleKnowledge") then
            return
        end

        -- Loop over every item to be rendered
        for i = 1, #items do
            local item = items[i]
            if item:getFullType() == "Base.Apple" then
                local flavour = item:getModData().flavour
                if flavour == "sweet" then
                    item:setName("Sweet Apple")
                elseif flavour == "sour" then
                    item:setName("Sour Apple")
                else
                    item:setName("Mysterious Apple")
                end
            end
        end
    end

    InventoryUI.preDisplayItems:addListener(setAppleName)
