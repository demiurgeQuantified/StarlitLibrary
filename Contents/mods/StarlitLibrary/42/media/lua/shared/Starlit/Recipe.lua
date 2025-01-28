local Recipe = {}

-- TODO: check if this even runs well lol
---@param arrayList ArrayList
---@param ... string
---@return InventoryItem? ...
---@nodiscard
Recipe.extractItems = function(arrayList, ...)
    ---@type string[]
    local wantedItems = table.newarray(...)
    ---@type { [string] : integer }
    local itemToIndex = {}
    for i = 1, #wantedItems do
        itemToIndex[wantedItems[i]] = i
    end

    ---@type (InventoryItem?)[]
    local foundItems = table.newarray(nil)
    for i = 0, arrayList:size()-1 do
        local item = arrayList:get(i) --[[@as InventoryItem]]
        local index = itemToIndex[item:getFullType()]
        if index then
            foundItems[index] = item
        end
    end

    return unpack(foundItems, 1, #wantedItems)
end

return Recipe