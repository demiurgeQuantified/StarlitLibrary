local ActionState = require("Starlit/action/ActionState")
local Actions = require("Starlit/action/Actions")


local core = getCore()


local ActionUI = {}

---Creates a tooltip for an action describing any failed requirements.
---@param action starlit.Action The action.
---@param failReasons starlit.ActionState.FailReasons FailReasons corresponding to the action.
---@return ISToolTip tooltip The tooltip.
---@nodiscard
ActionUI.createFailTooltip = function(action, failReasons)
    local tooltip = ISWorldObjectContextMenu.addToolTip() --[[@as ISToolTip]]

    -- we don't cache this because the player can change it midgame and that's annoying to catch
    local desaturatedBadColour = ColorInfo.new():set(core:getBadHighlitedColor())
    desaturatedBadColour:desaturate(0.3)

    local desaturatedBadColourString = string.format(
        "%f,%f,%f",
        desaturatedBadColour:getR(),
        desaturatedBadColour:getG(),
        desaturatedBadColour:getB()
    )

    tooltip.name = getText(action.name)
    local description = "<BHC> "

    for i = 1, #failReasons.predicates do
        description = description .. getText(action.predicates[failReasons.predicates[i]].description) .. "\n "
    end

    for i = 1, #failReasons.objects do
        local requirement = action.requiredObjects[failReasons.objects[i]]
        description = description .. " <INDENT:0> "
                                  .. getText("IGUI_StarlitLibrary_Action_Object")
                                  .. "\n <INDENT:8> <PUSHRGB:" .. desaturatedBadColourString .. "> "

        for j = 1, #requirement.predicates do
            description = description .. getText(requirement.predicates[j].description) .. "\n "
        end

        description = description .. " <POPRGB> "
    end

    for i = 1, #failReasons.items do
        local requirement = action.requiredItems[failReasons.items[i]]
        description = description .. " <INDENT:0> "
                                  .. getText("IGUI_StarlitLibrary_Action_Item")
                                  .. " <PUSHRGB:" .. desaturatedBadColourString .. "> \n"

        if requirement.types then
            description = description .. " <INDENT:8> "
                                      .. getText("IGUI_StarlitLibrary_Action_ItemTypeList")
                                      .. "\n <INDENT:16> "

            local itemNames = {}
            for j = 1, #requirement.types do
                itemNames[j] = getItemNameFromFullType(requirement.types[j])
            end
            description = description .. table.concat(itemNames, ", ")
        elseif requirement.tags then
            local tagNames = {}
            for j = 1, #requirement.tags do
                tagNames[j] = getText("IGUI_StarlitLibrary_TagDescription_" .. requirement.tags[j])
            end
            description = description .. table.concat(tagNames, "\n")
        end

        for j = 1, #requirement.predicates do
            description = description .. " <INDENT:8> " .. getText(requirement.predicates[j].description) .. " \n "
        end

        description = description .. " <POPRGB> "
    end

    tooltip.description = description

    return tooltip
end


---Conditions to show an action that cannot be performed.
---@class starlit.Action.TooltipConditions
---@field mustPass {items: string[], objects: string[], predicates: integer[]}


---@type {action: starlit.Action, tooltipConditions: starlit.Action.TooltipConditions}[]
local objectActions = {}


---@alias starlit.Action.ItemTooltipConditions {itemAs: string}


---@type {action: starlit.Action, conditions: starlit.Action.ItemTooltipConditions}[]
local itemActions = {}


---@param action starlit.Action
---@param tooltipConditions starlit.Action.TooltipConditions
ActionUI.addObjectAction = function(action, tooltipConditions)
    table.insert(objectActions, {action = action, tooltipConditions = tooltipConditions})
end


---@param action starlit.Action
---@param tooltipConditions starlit.Action.ItemTooltipConditions
ActionUI.addItemAction = function(action, tooltipConditions)
    table.insert(itemActions, {action = action, conditions = tooltipConditions})
end


---@type Callback_OnFillInventoryObjectContextMenu
local function showItemAction(playerIndex, context, items)
    local item = items[1]
    if type(item) == "table" then
        ---@cast item umbrella.ContextMenuItemStack
        item = item.items[1]
    end
    ---@cast item InventoryItem

    local character = getSpecificPlayer(playerIndex)
    for i = 1, #itemActions do
        local itemAction = itemActions[i]
        local forceParams = {
            items = {
                [itemAction.conditions.itemAs] = item
            }
        }

        local state, failReasons = ActionState.tryBuildActionState(
            itemAction.action,
            character,
            {},
            forceParams
        )

        if failReasons and failReasons.type ~= "forced" then
            local option = context:addOption(getText(itemAction.action.name))
            option.notAvailable = true
            option.toolTip = ActionUI.createFailTooltip(itemAction.action, failReasons)
        elseif state then
            context:addOption(
                getText(itemAction.action.name),
                state,
                Actions.queueAction
            )
        end
    end
end


Events.OnFillInventoryObjectContextMenu.Add(showItemAction)


---@type Callback_OnFillWorldObjectContextMenu
local function showObjectActions(playerNum, context, worldObjects, test)
    local character = getSpecificPlayer(playerNum)
    for i = 1, #objectActions do
        local objectAction = objectActions[i]
        local state, failReasons = ActionState.tryBuildActionState(
            objectAction.action,
            character,
            worldObjects
        )

        local optionName = getText(objectAction.action.name)
        if state then
            context:addOption(optionName, state, Actions.queueAction)
        elseif failReasons then
            local option = context:addOption(optionName)
            option.notAvailable = true
            option.toolTip = ActionUI.createFailTooltip(objectAction.action, failReasons)
        end
    end
end

Events.OnFillWorldObjectContextMenu.Add(showObjectActions)

return ActionUI