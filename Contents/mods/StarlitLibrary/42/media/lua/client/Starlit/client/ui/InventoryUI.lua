local Events = require("Starlit/LuaEvent")
local Colour = require("Starlit/utils/Colour")

---@type Starlit.Colour
local COLOUR_LABEL = table.newarray(1, 1, 0.8, 1)
---@type Starlit.Colour
local COLOUR_VALUE = table.newarray(1, 1, 1, 1)

local InventoryUI = {}

InventoryUI.onFillItemTooltip = Events.new()
---@alias Starlit.InventoryUI.Callback_OnFillItemTooltip fun(tooltip:ObjectTooltip, layout:Layout, item:InventoryItem)

local old_render = ISToolTipInv.render
---@diagnostic disable-next-line: duplicate-set-field
ISToolTipInv.render = function(self)
    local item = self.item

    if instanceof(item, "FluidContainer") then
        old_render(self)
        return
    end

    local itemMetatable = getmetatable(self.item).__index
    local old_DoTooltip = itemMetatable.DoTooltip
    ---@param tooltip ObjectTooltip
    itemMetatable.DoTooltip = function(self, tooltip)
        local layout = tooltip:beginLayout()
        item:DoTooltipEmbedded(tooltip, layout, 0)

        -- old_DoTooltip(self, tooltip)

        InventoryUI.onFillItemTooltip:trigger(tooltip, layout, item)

        local height = layout:render(tooltip.padLeft, layout.offsetY, tooltip)
        tooltip:endLayout(layout)
        tooltip:setHeight(height + tooltip.padBottom)
        if tooltip:getWidth() < 150 then
            tooltip:setWidth(150)
        end
    end

    old_render(self)

    itemMetatable.DoTooltip = old_DoTooltip
end

---Adds a label to a tooltip layout.
---@param layout Layout The tooltip layout.
---@param label string The text to display as a label.
---@param colour? Starlit.Colour The colour of the text.
InventoryUI.addTooltipLabel = function(layout, label, colour)
    local layoutItem = LayoutItem.new()
    layout.items:add(layoutItem)
    layoutItem:setLabel(label, Colour.getRGBA(colour or COLOUR_LABEL))
end

---Adds a key/value pair to a tooltip layout.
---@param layout Layout The tooltip layout.
---@param key string Key text.
---@param value string Value text.
---@param keyColour? Starlit.Colour Key colour.
---@param valueColour? Starlit.Colour Value colour.
InventoryUI.addTooltipKeyValue = function(layout, key, value, keyColour, valueColour)
    local layoutItem = LayoutItem.new()
    layout.items:add(layoutItem)
    layoutItem:setLabel(key, Colour.getRGBA(keyColour or COLOUR_LABEL))
    layoutItem:setValue(value, Colour.getRGBA(valueColour or COLOUR_VALUE))
end

---Adds a progress bar to a tooltip layout.
---@param layout Layout The tooltip layout.
---@param label string Label text.
---@param amount number How filled the bar should be, between 0 and 1.
---@param labelColour? Starlit.Colour Label colour.
---@param barColour? Starlit.Colour Colour of the filled part of the bar. Defaults to lerping between the user's good colour and bad colour by the amount.
InventoryUI.addTooltipBar = function(layout, label, amount, labelColour, barColour)
    local layoutItem = LayoutItem.new()
    layout.items:add(layoutItem)
    layoutItem:setLabel(label, Colour.getRGBA(labelColour or COLOUR_LABEL))
    layoutItem:setProgress(
        amount,
        Colour.getRGBA(barColour or Colour.lerpColour(Colour.badColour, Colour.goodColour, amount)))
end

---Adds an integer key/value to a tooltip layout.
---Positive values will be rendered with a plus.
---The value will be coloured in the user's good colour or bad colour depending on the value of highGood.
---If you just want a number shown without the plus or colouration, convert your number to a string and use addTooltipKeyValue.
---@param layout Layout The tooltip layout.
---@param label string Label text.
---@param value integer The integer value to show.
---@param highGood boolean If true, values above zero are shown in green and values below zero are shown in red. If false, the opposite is true.
---@param labelColour? Starlit.Colour Label colour.
InventoryUI.addTooltipInteger = function(layout, label, value, highGood, labelColour)
    local layoutItem = LayoutItem.new()
    layout.items:add(layoutItem)
    layoutItem:setLabel(label, Colour.getRGBA(labelColour or COLOUR_LABEL))
    layoutItem:setValueRight(value, highGood)
end

return InventoryUI