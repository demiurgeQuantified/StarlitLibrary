InventoryUI
===========
::

   local InventoryUI = require("Starlit/client/ui/InventoryUI")

The InventoryUI module contains utilities related to the character inventory UI. Currently it only contains utilities for item tooltips.

.. lua:module:: InventoryUI

Events
------

.. lua:data:: onFillItemTooltip LuaEvent

   Triggered whenever an inventory item's tooltip is being rendered. The Layout passed from this event is needed for most tooltip functions.

   :param ObjectTooltip tooltip: The tooltip being filled.
   :param Layout layout: The tooltip layout being filled.
   :param InventoryItem item: The item the tooltip is being filled for.

.. lua:data:: preRenderItems LuaEvent

   .. versionadded:: v1.5.0

   Triggered before items are rendered in the inventory panel.

   :param InventoryItem[] items: Items to render.
   :param IsoPlayer player: Player whose inventory panel is being rendered.

Functions
---------

.. lua:function:: addTooltipLabel(layout: Layout, label: string, colour: Starlit.Colour | nil) -> element: LayoutItem
   
   Adds a label to a tooltip layout.
   
   :param Layout layout: The tooltip layout
   :param label string: The text to display as a label.
   :param Starlit.Colour | nil colour: The colour of the text.
   :return LayoutItem element: The created tooltip element.

.. lua:function:: addTooltipKeyValue(layout: Layout, key: string, value: string, keyColour: Starlit.Colour | nil, valueColour: Starlit.Colour | nil) -> element: LayoutItem

   Adds a key/value pair to a tooltip layout.

   :param Layout layout: The tooltip layout.
   :param string key: Key text.
   :param string value: Value text.
   :param Starlit.Colour | nil keyColour: Key colour.
   :param Starlit.Colour | nil valueColour: Value colour.
   :return LayoutItem element: The created tooltip element.

.. lua:function:: addTooltipBar(layout: Layout, label: string, amount: number, labelColour: Starlit.Colour | nil, barColour: Starlit.Colour | nil) -> element: LayoutItem

   Adds a progress bar to a tooltip layout.

   :param Layout layout: The tooltip layout.
   :param string label: Label text.
   :param number amount: How filled the bar should be, between 0 and 1.
   :param Starlit.Colour | nil labelColour: Label colour.
   :param Starlit.Colour | nil barColour: Colour of the filled part of the bar. Defaults to lerping between the user's good colour and bad colour by the amount.
   :return LayoutItem element: The created tooltip element.

.. lua:function:: addTooltipInteger(layout: Layout, label: string, value: integer, highGood: boolean, labelColour: Starlit.Colour | nil) -> element: LayoutItem

   Adds an integer key/value to a tooltip layout.
   Positive values will be rendered with a plus.
   The value will be coloured in the user's good colour or bad colour depending on the value of highGood.
   If you just want a number shown without the plus or colouration, convert your number to a string and use addTooltipKeyValue.

   :param Layout layout: The tooltip layout.
   :param string label: Label text.
   :param integer value: The integer value to show.
   :param boolean highGood: If true, values above zero are shown in green and values below zero are shown in red. If false, the opposite is true.
   :param Starlit.Colour | nil labelColour: Label colour.
   :return LayoutItem element: The created tooltip element.

.. lua:function:: getTooltipElementByLabel(layout: Layout, label: string) -> item: LayoutItem | nil

   Finds and returns a layout element from its label. Useful to find elements added by Vanilla or other mods.

   :param Layout layout: The tooltip layout.
   :param label string: The string label of the element.
   :return LayoutItem | nil element: The layout item.

   .. note::
      It is best practice to use ``getText()`` for the label to ensure your code works in all game languages.
      Most Vanilla tooltip labels add ":" to the end of the translated string; you will need to replicate this to catch them.

.. lua:function:: getTooltipElementIndex(layout, element) -> integer

   Returns the index of the element in the tooltip layout.

   :param Layout layout: The tooltip layout.
   :param LayoutItem element: The tooltip element to get the index of.
   :return integer index: The index of the element, or -1 if the element does not belong to this layout.

.. lua:function:: removeTooltipElement(layout: Layout, element: LayoutItem | integer) -> LayoutItem | nil

   Removes an existing tooltip element from a tooltip.

   :param Layout layout: The tooltip layout.
   :param LayoutItem | integer element: The tooltip element to remove, or the index (from the top) of the element to remove. Negative indices count from the bottom.
   :return LayoutItem | nil element: The element that was removed.

.. lua:function:: moveTooltipElement(layout: Layout, element: LayoutItem, index: integer)

   Moves a layout element to a specific index, shifting elements down to make room.

   :param Layout layout: The tooltip layout.
   :param LayoutItem element: The tooltip element.
   :param integer index: The index to move the layout element to, counting from the top of the tooltip. Negative indices insert from the bottom up.

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
