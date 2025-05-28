local ActionUI = {}

---@param action starlit.Action
---@param failReasons starlit.ActionState.FailReasons
---@return ISToolTip
ActionUI.buildTooltip = function(action, failReasons)
    local tooltip = ISWorldObjectContextMenu.addToolTip() --[[@as ISToolTip]]

    tooltip.name = action.name
    local description = "<BHC> "

    for i = 1, #failReasons.predicates do
        description = description .. action.predicates[failReasons.predicates[i]].description .. "\n "
    end

    for i = 1, #failReasons.objects do
        local requirement = action.requiredObjects[failReasons.objects[i]]
        description = description .. " <INDENT:0> Any object: \n <INDENT:8> "
        for j = 1, #requirement.predicates do
            description = description .. requirement.predicates[j].description .. "\n "
        end
    end

    for i = 1, #failReasons.items do
        local requirement = action.requiredItems[failReasons.items[i]]
        description = description .. " <INDENT:0> Any item: \n"
        if requirement.types then
            description = description .. " <INDENT:8> One of: \n <INDENT:16>"
            local itemNames = {}
            for j = 1, #requirement.types do
                itemNames[j] = getItemNameFromFullType(requirement.types[j])
            end
            description = description .. table.concat(itemNames, ", ")
        elseif requirement.tags then
            -- TODO: there should be translation strings for tags, which explain what they do
            local tagNames = {}
            for j = 1, #requirement.tags do
                tagNames[j] = requirement.tags[j]
            end
            description = description .. table.concat(tagNames, "\n")
        end
        for j = 1, #requirement.predicates do
            description = description .. " <INDENT:8> " .. requirement.predicates[j].description .. " \n "
        end
        description = description .. "\n"
    end

    tooltip.description = description

    return tooltip
end

return ActionUI