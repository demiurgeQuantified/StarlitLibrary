---@namespace starlit

local LuaEvent = require("Starlit/LuaEvent")
local Colour = require("Starlit/utils/Colour")


---@type Starlit.Colour
local COLOUR_LABEL = table.newarray(1, 1, 0.8, 1)
---@type Starlit.Colour
local COLOUR_VALUE = table.newarray(1, 1, 1, 1)


local InventoryUI = {}


---@type LuaEvent<ObjectTooltip, Layout, InventoryItem>
InventoryUI.onFillItemTooltip = LuaEvent.new()

---Triggered before items are rendered in the inventory panel.
---@type LuaEvent<InventoryItem[], IsoPlayer>
InventoryUI.preRenderItems = LuaEvent.new()


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

        local padLeft = tooltip.padLeft
        local padBottom = tooltip.padBottom

        local height = layout:render(padLeft, layout.offsetY, tooltip)
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
            local maxX = width - tooltip.padRight
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
---@param layout Layout The tooltip layout.
---@param label string The text to display as a label.
---@param colour? Starlit.Colour The colour of the text.
---@return LayoutItem element The created tooltip element.
InventoryUI.addTooltipLabel = function(layout, label, colour)
    local layoutItem = layout:addItem()
    layoutItem:setLabel(label, Colour.getRGBA(colour or COLOUR_LABEL))
    return layoutItem
end


---Adds a key/value pair to a tooltip layout.
---@param layout Layout The tooltip layout.
---@param key string Key text.
---@param value string Value text.
---@param keyColour? Starlit.Colour Key colour.
---@param valueColour? Starlit.Colour Value colour.
---@return LayoutItem element The created tooltip element.
InventoryUI.addTooltipKeyValue = function(layout, key, value, keyColour, valueColour)
    local layoutItem = layout:addItem()
    layoutItem:setLabel(key, Colour.getRGBA(keyColour or COLOUR_LABEL))
    layoutItem:setValue(value, Colour.getRGBA(valueColour or COLOUR_VALUE))
    return layoutItem
end


---Adds a progress bar to a tooltip layout.
---@param layout Layout The tooltip layout.
---@param label string Label text.
---@param amount number How filled the bar should be, between 0 and 1.
---@param labelColour? Starlit.Colour Label colour.
---@param barColour? Starlit.Colour Colour of the filled part of the bar. Defaults to lerping between the user's good colour and bad colour by the amount.
---@return LayoutItem element The created tooltip element.
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
---@param layout Layout The tooltip layout.
---@param label string Label text.
---@param value integer The integer value to show.
---@param highGood boolean If true, values above zero are shown in green and values below zero are shown in red. If false, the opposite is true.
---@param labelColour? Starlit.Colour Label colour.
---@return LayoutItem element The created tooltip element.
InventoryUI.addTooltipInteger = function(layout, label, value, highGood, labelColour)
    local layoutItem = layout:addItem()
    layoutItem:setLabel(label, Colour.getRGBA(labelColour or COLOUR_LABEL))
    layoutItem:setValueRight(value, highGood)
    return layoutItem
end


---Find and returns a layout element from its label. Useful to find elements added by Vanilla or other mods.
---@param layout Layout The tooltip layout.
---@param label string 
---@return LayoutItem?
InventoryUI.getTooltipElementByLabel = function(layout, label)
    local items = layout.items --[[@as ArrayList]]
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item.label == label then
            return item
        end
    end
end


---Returns the index of the element in the tooltip layout.
---@param layout Layout The tooltip layout.
---@param element LayoutItem The tooltip element to get the index of.
---@return integer index The index of the element, or -1 if the element does not belong to this layout.
InventoryUI.getTooltipElementIndex = function(layout, element)
    return layout.items:indexOf(element)
end


---Removes an existing tooltip element from a tooltip.
---@param layout Layout The tooltip layout.
---@param element LayoutItem | integer The tooltip element to remove, or the index (from the top) of the element to remove. Negative indices count from the bottom.
---@return LayoutItem? element The element that was removed.
InventoryUI.removeTooltipElement = function(layout, element)
    local items = layout.items --[[@as ArrayList]]

    local argType = type(element)
    if argType == "string" then
        -- TODO: this is deprecated. It is not documented in the type annotations and should be removed in the future.
        ---@cast element string

        for i = 0, items:size() - 1 do
            local item = items:get(i)
            if item.label == element then
                items:remove(item)
                return item
            end
        end
    elseif argType == "number" then
        ---@cast element integer
        if element < 0 then
            element = items:size() + element
        end
        return items:remove(element)
    else
        ---@cast element LayoutItem
        items:remove(element)
        return element
    end
end


---Moves a layout element to a specific index, shifting elements down to make room.
---@param layout Layout The tooltip layout.
---@param element LayoutItem The tooltip element.
---@param index integer The index to move the layout element to, counting from the top of the tooltip. Negative indices insert from the bottom up.
InventoryUI.moveTooltipElement = function(layout, element, index)
    local items = layout.items --[[@as ArrayList]]
    items:remove(element)
    if index < 0 then
        index = items:size() + index
    end
    items:add(index, element)
end


return InventoryUI