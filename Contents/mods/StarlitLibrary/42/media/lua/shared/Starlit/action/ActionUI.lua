local ActionState = require("Starlit/action/ActionState")
local Actions = require("Starlit/action/Actions")
local Colour  = require("Starlit/utils/Colour")


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

    tooltip.name = action.name
    local description = "<BHC> "

    for i = 1, #failReasons.predicates do
        description = description .. action.predicates[failReasons.predicates[i]].description .. "\n "
    end

    for i = 1, #failReasons.objects do
        local requirement = action.requiredObjects[failReasons.objects[i]]
        description = description .. " <INDENT:0> "
                                  .. getText("IGUI_StarlitLibrary_Action_Object")
                                  .. "\n <INDENT:8> <PUSHRGB:" .. desaturatedBadColourString .. "> "

        for j = 1, #requirement.predicates do
            description = description .. requirement.predicates[j].description .. "\n "
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
            description = description .. " <INDENT:8> " .. requirement.predicates[j].description .. " \n "
        end

        description = description .. " <POPRGB> "
    end

    tooltip.description = description

    return tooltip
end


--- TODO: use selfMergeTable to set defaults for these

---Configuration for when and how a tooltip should be displayed.
---@class starlit.Action.TooltipConfiguration
---
---Configures object highlighting when the action's option is selected.
---@field highlight {object: string, colour: Starlit.Colour | nil} | nil
---
---Conditions that must pass for a fail tooltip to be shown.  # TODO: not implemented
---@field mustPass {items: string[], objects: string[], predicates: integer[]}
---
---The translation string of the name of the submenu the action should be added to.  # TODO: not implemented
---@field subMenu string | nil
---
---How to behave when more than one action of this type is available.
---'separate' creates a separate option for each action.
---'submenu' merges the options into a submenu.
---'hide' removes all duplicates, leaving only one action left.
---@field duplicatePolicy "separate"|"submenu"|"hide"


---@alias starlit.ActionUI.ObjectAction {action: starlit.Action, config: starlit.Action.TooltipConfiguration}
---@type starlit.ActionUI.ObjectAction[]
local objectActions = {}


---@alias starlit.Action.ItemTooltipConditions {itemAs: string}


---@type {action: starlit.Action, conditions: starlit.Action.ItemTooltipConditions}[]
local itemActions = {}


---@param action starlit.Action
---@param tooltipConditions starlit.Action.TooltipConfiguration
ActionUI.addObjectAction = function(action, tooltipConditions)
    table.insert(objectActions, {action = action, config = tooltipConditions})
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
            local option = context:addOption(itemAction.action.name)
            option.notAvailable = true
            option.toolTip = ActionUI.createFailTooltip(itemAction.action, failReasons)
        elseif state then
            context:addOption(
                itemAction.action.name,
                state,
                Actions.queueAction
            )
        end
    end
end


Events.OnFillInventoryObjectContextMenu.Add(showItemAction)


---@type Starlit.Colour
local defaultHighlightColour = {0.9, 1, 0, 1}


---@param highlighted boolean
---@param object IsoObject
---@param r number
---@param g number
---@param b number
---@param a number
local function highlightObjectOnHover(_, _, highlighted, object, r, g, b, a)
    if highlighted then
        object:setHighlightColor(r, g, b, a)
    end
    object:setHighlighted(highlighted, false)
end


---@param context ISContextMenu
---@param state starlit.ActionState
---@param config starlit.Action.TooltipConfiguration
---@return unknown? option no typedef for this in umbrella grr
local function addStateOption(context, state, config)
    local option = context:addOption(state.def.name, state, Actions.queueAction)
    local highlight = config.highlight
    if highlight ~= nil then
        option.onHighlight = highlightObjectOnHover
        option.onHighlightParams = {state.objects[highlight.object], Colour.getRGBA(highlight.colour or defaultHighlightColour)}
    end
    return option
end


---@param context ISContextMenu
---@param name string
---@return ISContextMenu subMenu
local function addSubMenu(context, name)
    local subMenuOption = context:addOption(name)
    local subMenu = ISContextMenu:getNew(context)
    context:addSubMenu(subMenuOption, subMenu)
    return subMenu
end


---@type Callback_OnFillWorldObjectContextMenu
local function showObjectActions(playerNum, context, worldObjects, test)
    ---@type {[starlit.ActionUI.ObjectAction]: starlit.ActionState[]}
    local statesByAction = {}

    local character = getSpecificPlayer(playerNum)
    for i = 1, #objectActions do
        local objectAction = objectActions[i]
        local state, failReasons = ActionState.tryBuildActionState(
            objectAction.action,
            character,
            worldObjects
        )

        local optionName = objectAction.action.name
        if state then
            if not statesByAction[objectAction] then
                statesByAction[objectAction] = {}
            end
            table.insert(statesByAction[objectAction], state)
            table.insert(statesByAction[objectAction], state) -- DELETEME duplicate for submenu merge testing
        elseif failReasons then
            local option = context:addOption(optionName)
            option.notAvailable = true
            option.toolTip = ActionUI.createFailTooltip(objectAction.action, failReasons)
        end
    end

    for action, states in pairs(statesByAction) do
        local duplicatePolicy = action.config.duplicatePolicy
        -- make context local to this scope so we don't propagate changes to other actions
        local context = context

        if action.config.subMenu then
            local option = context:getOptionFromName(action.config.subMenu)
            if option then
                assert(option.subOption ~= nil)
                context = context:getSubMenu(option.subOption)
            else
                context = addSubMenu(context, action.config.subMenu)
            end
        end

        if #states == 1 or duplicatePolicy == "hide" then
            addStateOption(context, states[1], action.config)
        else
            if duplicatePolicy == "submenu" then
                context = addSubMenu(context, action.action.name)
            end
            for i = 1, #states do
                addStateOption(context, states[i], action.config)
            end
        end
    end
end

Events.OnFillWorldObjectContextMenu.Add(showObjectActions)

return ActionUI