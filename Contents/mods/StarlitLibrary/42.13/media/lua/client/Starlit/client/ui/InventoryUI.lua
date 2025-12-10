---@namespace starlit

local LuaEvent = require("Starlit/LuaEvent")
local Colour = require("Starlit/utils/Colour")


---@type Starlit.Colour
local COLOUR_LABEL = table.newarray(1, 1, 0.8, 1)
---@type Starlit.Colour
local COLOUR_VALUE = table.newarray(1, 1, 1, 1)


local InventoryUI = {}


---@type LuaEvent<ObjectTooltip, ObjectTooltip.Layout, InventoryItem>
InventoryUI.onFillItemTooltip = LuaEvent.new() ---@as LuaEvent<ObjectTooltip, ObjectTooltip.Layout, InventoryItem>

---Triggered before items are rendered in the inventory panel.
---@type LuaEvent<InventoryItem[], IsoPlayer>
InventoryUI.preRenderItems = LuaEvent.new() ---@as LuaEvent<InventoryItem[], IsoPlayer>


local old_refreshContainer = ISInventoryPane.refreshContainer

function ISInventoryPane:refreshContainer()
    local player = getSpecificPlayer(self.player)
    ---@type InventoryItem[]
    local items = table.newarray()

    local javaItems = self.inventory:getItems()
    -- TODO: this doesn't allow you to elegantly add suffixes to the name
    --  a callback inside of InventoryItem.getName during old_refreshContainer could do this better
    for i = 0, javaItems:size() - 1 do
        items[i + 1] = javaItems:get(i)
    end

    InventoryUI.preRenderItems:trigger(items, player)
    old_refreshContainer(self)
end


local old_render = ISToolTipInv.render
---@diagnostic disable-next-line: duplicate-set-field
ISToolTipInv.render = function(self)
    local item = self.item ---@as InventoryItem | FluidContainer

    if instanceof(item, "FluidContainer") then
        ---@cast item FluidContainer
        old_render(self)
        return
    end
    ---@cast item -FluidContainer

    local itemMetatable = getmetatable(item).__index
    local old_DoTooltip = itemMetatable.DoTooltip
    ---@param tooltip ObjectTooltip
    itemMetatable.DoTooltip = function(self, tooltip)
        local layout = tooltip:beginLayout()
        item:DoTooltipEmbedded(tooltip, layout, 0)

        -- because we no longer call the original function, this may affect mod compatibility
        -- there isn't really any way to avoid that though

        InventoryUI.onFillItemTooltip:trigger(tooltip, layout, item)

        ---@diagnostic disable-next-line: undefined-field
        local padLeft = tooltip.padLeft ---@as integer
        ---@diagnostic disable-next-line: undefined-field
        local padBottom = tooltip.padBottom ---@as integer

        ---@diagnostic disable-next-line: undefined-field
        local height = layout:render(padLeft, layout.offsetY --[[@as integer]], tooltip)
        tooltip:endLayout(layout)

        local width = tooltip:getWidth()
        if width < 150 then
            width = 150
        end

        if instanceof(item, "InventoryContainer") then
            if width < 160 then
                width = 160
            end
            ---@cast item InventoryContainer
            local items = item:getItemContainer():getItems()
            ---@diagnostic disable-next-line: undefined-field
            local maxX = width - tooltip.padRight ---@as integer
            if not items:isEmpty() then
                ---@type {[string] : true}
                local seenItems = {}
                local xOffset = padLeft
                height = height + 4
                for i = items:size() - 1, 0, -1 do
                    local item = items:get(i) --[[@as InventoryItem]]
                    local name = item:getName()
                    if not seenItems[name] then
                        seenItems[name] = true
                        tooltip:DrawTextureScaledAspect(item:getTex(), xOffset, height, 16, 16, 1, 1, 1, 1)
                        xOffset = xOffset + 17
                        if xOffset + 16 > maxX then
                            break
                        end
                    end
                end

                height = height + 16
            end
        end

        tooltip:setHeight(height + padBottom)
        tooltip:setWidth(width)
    end

    old_render(self)

    itemMetatable.DoTooltip = old_DoTooltip
end


---Adds a label to a tooltip layout.
---@param layout ObjectTooltip.Layout The tooltip layout.
---@param label string The text to display as a label.
---@param colour? Starlit.Colour The colour of the text.
---@return ObjectTooltip.LayoutItem element The created tooltip element.
InventoryUI.addTooltipLabel = function(layout, label, colour)
    local layoutItem = layout:addItem()
    layoutItem:setLabel(label, Colour.getRGBA(colour or COLOUR_LABEL))
    return layoutItem
end


---Adds a key/value pair to a tooltip layout.
---@param layout ObjectTooltip.Layout The tooltip layout.
---@param key string Key text.
---@param value string Value text.
---@param keyColour? Starlit.Colour Key colour.
---@param valueColour? Starlit.Colour Value colour.
---@return ObjectTooltip.LayoutItem element The created tooltip element.
InventoryUI.addTooltipKeyValue = function(layout, key, value, keyColour, valueColour)
    local layoutItem = layout:addItem()
    layoutItem:setLabel(key, Colour.getRGBA(keyColour or COLOUR_LABEL))
    layoutItem:setValue(value, Colour.getRGBA(valueColour or COLOUR_VALUE))
    return layoutItem
end


---Adds a progress bar to a tooltip layout.
---@param layout ObjectTooltip.Layout The tooltip layout.
---@param label string Label text.
---@param amount number How filled the bar should be, between 0 and 1.
---@param labelColour? Starlit.Colour Label colour.
---@param barColour? Starlit.Colour Colour of the filled part of the bar. Defaults to lerping between the user's good colour and bad colour by the amount.
---@return ObjectTooltip.LayoutItem element The created tooltip element.
InventoryUI.addTooltipBar = function(layout, label, amount, labelColour, barColour)
    local layoutItem = layout:addItem()
    layoutItem:setLabel(label, Colour.getRGBA(labelColour or COLOUR_LABEL))
    layoutItem:setProgress(
        amount,
        Colour.getRGBA(barColour or Colour.lerpColour(Colour.badColour, Colour.goodColour, amount)))
    return layoutItem
end


---Adds an integer key/value to a tooltip layout.
---Positive values will be rendered with a plus.
---The value will be coloured in the user's good colour or bad colour depending on the value of highGood.
---If you just want a number shown without the plus or colouration, convert your number to a string and use addTooltipKeyValue.
---@param layout ObjectTooltip.Layout The tooltip layout.
---@param label string Label text.
---@param value integer The integer value to show.
---@param highGood boolean If true, values above zero are shown in green and values below zero are shown in red. If false, the opposite is true.
---@param labelColour? Starlit.Colour Label colour.
---@return ObjectTooltip.LayoutItem element The created tooltip element.
InventoryUI.addTooltipInteger = function(layout, label, value, highGood, labelColour)
    local layoutItem = layout:addItem()
    layoutItem:setLabel(label, Colour.getRGBA(labelColour or COLOUR_LABEL))
    layoutItem:setValueRight(value, highGood)
    return layoutItem
end


---Find and returns a layout element from its label. Useful to find elements added by Vanilla or other mods.
---@param layout ObjectTooltip.Layout The tooltip layout.
---@param label string 
---@return ObjectTooltip.LayoutItem?
InventoryUI.getTooltipElementByLabel = function(layout, label)
    ---@diagnostic disable-next-line: undefined-field
    local items = layout.items --[[@as ArrayList<ObjectTooltip.LayoutItem>]]
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        ---@diagnostic disable-next-line: undefined-field
        if item.label --[[@as string]] == label then
            return item
        end
    end
end


---Returns the index of the element in the tooltip layout.
---@param layout ObjectTooltip.Layout The tooltip layout.
---@param element ObjectTooltip.LayoutItem The tooltip element to get the index of.
---@return integer index The index of the element, or -1 if the element does not belong to this layout.
InventoryUI.getTooltipElementIndex = function(layout, element)
    ---@diagnostic disable-next-line: undefined-field
    return layout.items--[[@as ArrayList<ObjectTooltip.LayoutItem>]]:indexOf(element)
end


---Removes an existing tooltip element from a tooltip.
---@param layout ObjectTooltip.Layout The tooltip layout.
---@param element ObjectTooltip.LayoutItem | integer The tooltip element to remove, or the index (from the top) of the element to remove. Negative indices count from the bottom.
---@return ObjectTooltip.LayoutItem? element The element that was removed.
InventoryUI.removeTooltipElement = function(layout, element)
    ---@diagnostic disable-next-line: undefined-field
    local items = layout.items --[[@as ArrayList<ObjectTooltip.LayoutItem>]]

    local argType = type(element)
    if argType == "string" then
        -- TODO: this is deprecated. It is not documented in the type annotations and should be removed in the future.
        ---@cast element string

        for i = 0, items:size() - 1 do
            local item = items:get(i)
            ---@diagnostic disable-next-line: undefined-field
            if item.label --[[@as string]] == element then
                items:remove(item)
                return item
            end
        end
    elseif argType == "number" then
        if element < 0 then
            element = items:size() + element
        end
        ---@diagnostic disable-next-line: return-type-mismatch
        return items:remove(element)
    else
        items:remove(element)
        return element
    end
end


---Moves a layout element to a specific index, shifting elements down to make room.
---@param layout ObjectTooltip.Layout The tooltip layout.
---@param element ObjectTooltip.LayoutItem The tooltip element.
---@param index integer The index to move the layout element to, counting from the top of the tooltip. Negative indices insert from the bottom up.
InventoryUI.moveTooltipElement = function(layout, element, index)
    ---@diagnostic disable-next-line: undefined-field
    local items = layout.items --[[@as ArrayList<ObjectTooltip.LayoutItem>]]
    items:remove(element)
    if index < 0 then
        index = items:size() + index
    end
    ---no idea why emmylua thinks this is wrong
    ---@diagnostic disable-next-line: redundant-parameter, param-type-mismatch
    items:add(index, element)
end


return InventoryUI