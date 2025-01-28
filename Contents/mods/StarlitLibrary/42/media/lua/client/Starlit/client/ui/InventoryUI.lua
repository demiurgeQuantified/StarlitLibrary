local Events = require "Starlit/LuaEvent"

local InventoryUI = {}

InventoryUI.onFillItemTooltip = Events.new()
---@alias Starlit.InventoryUI.Callback_OnFillItemTooltip fun(tooltip:ObjectTooltip, layout:Layout, item:InventoryItem)

local old_render = ISToolTipInv.render
---@diagnostic disable-next-line: duplicate-set-field
ISToolTipInv.render = function(self)
    local layout = self.tooltip--[[@as ObjectTooltip]]:beginLayout()
    self.tooltip.freeLayouts:push(layout)
    local item = self.item

    local itemMetatable = getmetatable(self.item).__index
    local old_DoTooltip = itemMetatable.DoTooltip
    itemMetatable.DoTooltip = function(self, tooltip)
        old_DoTooltip(self, tooltip)

        InventoryUI.onFillItemTooltip:trigger(tooltip, layout, item)

        local height = layout:render(tooltip.padLeft, tooltip:getHeight() - tooltip.padBottom, tooltip)
        tooltip:setHeight(height + tooltip.padBottom)
        layout.items:clear()
    end

    old_render(self)

    itemMetatable.DoTooltip = old_DoTooltip
end

return InventoryUI