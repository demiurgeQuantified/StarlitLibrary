local ActionState = require("Starlit/action/ActionState")
local Actions = require("Starlit/action/Actions")
local Colour  = require("Starlit/utils/Colour")
local SelfMergeTable = require("Starlit/utils/SelfMergeTable")


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


---Configuration for showing tooltips for invalid actions.
---@class starlit.Action.ShowFailConditions
---
---If true, a fail tooltip will only be shown if no valid action of the same type was found.
---@field noSuccesses boolean
---
---If true, only one fail will be shown, even if multiple were found.
---@field onlyOne boolean
---
---Lists of conditions that must pass for a fail tooltip to be considered to be shown.
---For example, you generally don't want to show a tooltip for a world action if the object is invalid,
---or a tooltip for an item action when the selected item is the wrong type.
---@field required {objects: any[] | nil, items: any[] | nil, predicates: any[] | nil} | nil


---Args for creating a TooltipConfiguration.
---Differs from TooltipConfiguration only in that all fields are marked as nullable.
---@class starlit.Action.TooltipConfigurationArgs
---
---Configures object highlighting when the action's option is selected.
---@field highlight {object: string, colour: Starlit.Colour | nil} | nil
---
---The translation string of the name of the submenu the action should be added to.  # TODO: not implemented
---@field subMenu string | nil
---
---How to behave when more than one action of this type is available.
---'separate' creates a separate option for each action.
---'submenu' merges the options into a submenu.
---'hide' removes all duplicates, leaving only one action left.
---@field duplicatePolicy "separate" | "submenu" | "hide" | nil
---
---Conditions for when options for invalid actions should be shown.
---@field showFailConditions starlit.Action.ShowFailConditions | nil


---Concrete configuration for when and how a tooltip should be displayed.
---@class starlit.Action.TooltipConfiguration : starlit.Action.TooltipConfigurationArgs
---@overload fun(config:starlit.Action.TooltipConfigurationArgs):self
---
---How to behave when more than one action of this type is available.
---'separate' creates a separate option for each action.
---'submenu' merges the options into a submenu.
---'hide' removes all duplicates, leaving only one action left.
---@field duplicatePolicy "separate"|"submenu"|"hide"
---
---Conditions for when options for invalid actions should be shown.
---@field showFailConditions starlit.Action.ShowFailConditions


---@type starlit.Action.TooltipConfiguration
---@diagnostic disable-next-line: assign-type-mismatch
ActionUI.TooltipConfiguration = SelfMergeTable{
    duplicatePolicy = "submenu",
    showFailConditions = {
        noSuccesses = true,
        onlyOne = true
    }
}


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


-- TODO: this function needs to be broken up, it's too big

---@type Callback_OnFillWorldObjectContextMenu
local function showObjectActions(playerNum, context, worldObjects, test)
    ---@type {[starlit.ActionUI.ObjectAction]: {states: starlit.ActionState[], fails: starlit.ActionState.FailReasons}}
    local foundActions = {}

    local character = getSpecificPlayer(playerNum)
    for i = 1, #objectActions do
        local objectAction = objectActions[i]
        local state, failReasons = ActionState.tryBuildActionState(
            objectAction.action,
            character,
            worldObjects
        )

        -- TODO: add objectAs similar to inventory itemAs, if set try each object against that requirement and generate options for each
        --  this would let us e.g. highlight each window when trying to install glass, and show why that one isn't okay

        if state then
            if not foundActions[objectAction] then
                foundActions[objectAction] = {
                    states = {},
                    fails = {}
                }
            end
            table.insert(foundActions[objectAction].states, state)
        elseif failReasons then
            if not foundActions[objectAction] then
                foundActions[objectAction] = {
                    states = {},
                    fails = {}
                }
            end
            table.insert(foundActions[objectAction].fails, failReasons)
        end
    end

    for action, found in pairs(foundActions) do
        local menu = context

        if action.config.subMenu then
            local option = menu:getOptionFromName(action.config.subMenu)
            if option then
                assert(option.subOption ~= nil)
                menu = menu:getSubMenu(option.subOption)
            else
                menu = addSubMenu(menu, action.config.subMenu)
            end
        end

        local showFails = not action.config.showFailConditions.noSuccesses or #found.states == 0

        local totalNumber = #found.states
        if showFails then
            totalNumber = totalNumber + #found.fails
        end

        local duplicatePolicy = action.config.duplicatePolicy

        if totalNumber > 1 and duplicatePolicy == "submenu" then
            menu = addSubMenu(menu, action.action.name)
        end

        local states = found.states
        if #states > 0 then
            if #states == 1 or duplicatePolicy == "hide" then
                addStateOption(menu, states[1], action.config)
            else
                for i = 1, #states do
                    addStateOption(menu, states[i], action.config)
                end
            end
        end

        if showFails and #found.fails > 0 then
            if action.config.showFailConditions.onlyOne then
                found.fails = {found.fails[1]}
            end

            for i = 1, #found.fails do
                local option = menu:addOption(action.action.name)
                option.notAvailable = true
                option.toolTip = ActionUI.createFailTooltip(action.action, found.fails[i])
            end
        end
    end
end

Events.OnFillWorldObjectContextMenu.Add(showObjectActions)

return ActionUI