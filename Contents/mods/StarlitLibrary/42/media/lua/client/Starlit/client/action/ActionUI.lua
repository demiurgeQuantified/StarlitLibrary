local ActionState = require("Starlit/action/ActionState")
local ActionTester = require("Starlit/action/ActionTester")
local Actions = require("Starlit/action/Actions")
local Colour  = require("Starlit/utils/Colour")
local SelfMergeTable = require("Starlit/utils/SelfMergeTable")


local core = getCore()


-- what a horrible function name
---@return string
local function pushDesaturatedBadColour()
    local badColour = ColorInfo.new():set(core:getBadHighlitedColor())
    badColour:desaturate(0.3)

    return string.format(
        " <PUSHRGB:%f,%f,%f> ",
        badColour:getR(),
        badColour:getG(),
        badColour:getB()
    )
end


---@return string
local function pushDesaturatedGoodColour()
    local goodColour = ColorInfo.new():set(core:getGoodHighlitedColor())
    goodColour:desaturate(0.3)

    return string.format(
        " <PUSHRGB:%f,%f,%f> ",
        goodColour:getR(),
        goodColour:getG(),
        goodColour:getB()
    )
end


-- TODO: if the item/object was forced, it should say 'Selected item/object:' instead of "Any item/object:"


---@param requiredObjects table<any, starlit.Action.RequiredObject>
---@param objects table<any, starlit.ActionTester.ObjectResult>
---@return string
---@nodiscard
local function buildObjectsString(requiredObjects, objects)
    local result = ""

    for name, requirement in pairs(requiredObjects) do
        local objectResult = objects[name]
        if objectResult ~= nil then
            result = result .. (objectResult.success and " <GHC> " or " <BHC> ")
                            .. " <INDENT:0> "
                            .. getText("IGUI_StarlitLibrary_Action_Object")
                            .. "\n <INDENT:8> "

            for name, predicate in pairs(requirement.predicates) do
                if objectResult.predicates[name] == true then
                    result = result .. pushDesaturatedGoodColour()
                else
                    result = result .. pushDesaturatedBadColour()
                end
                result = result .. predicate.description .. " <POPRGB> \n"
            end

            result = result .. " <POPRGB> "
        end
    end

    result = result .. " <INDENT:0> "

    return result
end


---@param requiredItems table<any, starlit.Action.RequiredItem>
---@param items table<any, starlit.ActionTester.ItemResult[]>
---@return string
---@nodiscard
local function buildItemsString(requiredItems, items)
    local pushDesaturatedGoodColour = pushDesaturatedGoodColour()
    local pushDesaturatedBadColour = pushDesaturatedBadColour()
    local result = ""

    for name, requirement in pairs(requiredItems) do
        local itemResult = items[name]

        local numFound = 0
        -- we want to show the first failure as that will be the only detailed one
        ---@type starlit.ActionTester.ItemResult
        local showResult
        for i = 1, #itemResult do
            if not itemResult[i].success then
                showResult = itemResult[i]
                break
            end
            numFound = numFound + 1
        end
        -- if there were no failures, just show the first one
        if not showResult then
            showResult = itemResult[1]
        end

        if itemResult ~= nil then
            local itemText
            if requirement.uses > 0 then
                itemText = getText("IGUI_StarlitLibrary_Action_ItemUses", requirement.uses, numFound)
            elseif requirement.count > 1 then
                itemText = getText("IGUI_StarlitLibrary_Action_Items", requirement.count, numFound)
            else
                itemText = getText("IGUI_StarlitLibrary_Action_Item")
            end

            result = result .. (showResult.success and " <GHC> " or " <BHC> ")
                            .. " <INDENT:0> "
                            .. itemText
                            .. " \n"

            if requirement.types or requirement.tags then
                if showResult.validType == true then
                    result = result .. pushDesaturatedGoodColour
                else
                    result = result .. pushDesaturatedBadColour
                end

                if requirement.types then
                    -- TODO: when only one item type is needed, the 'One of:' header seems unnecessary
                    result = result .. " <INDENT:8> "
                                              .. getText("IGUI_StarlitLibrary_Action_ItemTypeList")
                                              .. "\n <INDENT:16> "

                    local itemNames = {}
                    for j = 1, #requirement.types do
                        itemNames[j] = getItemNameFromFullType(requirement.types[j])
                    end
                    result = result .. table.concat(itemNames, ", ") .. " <POPGRB> \n"
                else
                    local tagNames = {}
                    for j = 1, #requirement.tags do
                        tagNames[j] = getText("IGUI_StarlitLibrary_TagDescription_" .. requirement.tags[j])
                    end
                    result = result .. " <INDENT:8> " .. table.concat(tagNames, "\n") .. " <POPRGB> \n"
                end
            end

            for name, predicate in pairs(requirement.predicates) do
                if showResult.predicates[name] == true then
                    result = result .. pushDesaturatedGoodColour
                else
                    result = result .. pushDesaturatedBadColour
                end
                result = result .. " <INDENT:8> " .. predicate.description .. " <POPRGB> \n"
            end

            if requirement.consumed then
                result = result .. " <INDENT:8> <PUSHRGB:1,1,1> "
                                .. getText("IGUI_StarlitLibrary_Action_ItemConsumed")
                                .. " <POPRGB> \n"
            end
        end
    end

    result = result .. " <INDENT:0> "

    return result
end


---@param requiredSkills table<Perk, integer>
---@param testResult starlit.ActionTester.Result
---@return string
---@nodiscard
local function buildSkillsString(requiredSkills, testResult)
    local result = ""

    for perk, passed in pairs(testResult.skills) do
        if passed then
            result = result .. " <GHC> "
        else
            result = result .. " <BHC> "
        end

        result = result .. getText("IGUI_Skill")
                        .. string.format(
                            ": %s %d/%d\n",
                            perk:getName(),
                            testResult.character:getPerkLevel(perk),
                            requiredSkills[perk])
    end

    return result
end


local ActionUI = {}


---Creates a tooltip for an action describing any requirements.
---@param action starlit.Action The action.
---@param testResult starlit.ActionTester.Result Result of the action test.
---@return ISToolTip tooltip The tooltip.
---@nodiscard
ActionUI.createTooltip = function(action, testResult)
    local tooltip = ISWorldObjectContextMenu.addToolTip() --[[@as ISToolTip]]

    tooltip.name = action.name

    local description = ""

    for name, predicate in pairs(action.predicates) do
        if testResult.predicates[name] == true then
            description = description .. " <GHC> "
        else
            description = description .. " <BHC> "
        end
        description = description .. predicate.description .. "\n"
    end

    description = description .. buildObjectsString(action.requiredObjects, testResult.objects)
                              .. buildItemsString(action.requiredItems, testResult.items)
                              .. buildSkillsString(action.requiredSkills, testResult)

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
---or a tooltip for an item action when the selected item is the wrong type.  # TODO: allow specifying subconditions (item predicates etc) that must be met
---@field required {objects: table<any, true> | nil, items: table<any, true> | nil, predicates: table<any, true> | nil} | nil


---@alias starlit.Action.HighlightParams {object: string, colour: Starlit.Colour | nil}


---Args for creating a TooltipConfiguration.
---Differs from TooltipConfiguration only in that all fields are marked as nullable.
---@class starlit.Action.TooltipConfigurationArgs
---
---Configures object highlighting when the action's option is selected.
---@field highlight starlit.Action.HighlightParams | nil
---
---The translation string of the name of the submenu the action should be added to.
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
---
---If not nil, each object tested will be tested as the action's required object by the same name.
---This causes more tests overall to be ran, but can generate more helpful tooltips, depending on the kind of action.
---@field objectAs any
---
---If not nil, this function will be called to retrieve text for a tooltip when the action is valid.
---@field getTooltipText (fun(state:starlit.ActionState):text:string) | nil


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
---@param tooltipConditions starlit.Action.TooltipConfiguration | nil
ActionUI.addObjectAction = function(action, tooltipConditions)
    if not tooltipConditions then
        tooltipConditions = ActionUI.TooltipConfiguration{}
    end
    table.insert(objectActions, {action = action, config = tooltipConditions})
end


---@param action starlit.Action
---@param tooltipConditions starlit.Action.ItemTooltipConditions | nil
ActionUI.addItemAction = function(action, tooltipConditions)
    if not tooltipConditions then
        tooltipConditions = ActionUI.TooltipConfiguration{}
    end
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

    local tester = ActionTester.new(getSpecificPlayer(playerIndex))

    for i = 1, #itemActions do
        local itemAction = itemActions[i]
        local forceParams = {
            items = {
                [itemAction.conditions.itemAs] = {item}
            }
        }

        local result = tester:test(
            itemAction.action,
            {},
            forceParams
        )

        if not result.success then
            local option = context:addOption(itemAction.action.name)
            option.notAvailable = true
            option.toolTip = ActionUI.createTooltip(itemAction.action, result)
        else
            context:addOption(
                itemAction.action.name,
                ActionState.fromTestResult(result),
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
local function highlightObjectOnSelect(_, _, highlighted, object, r, g, b, a)
    if highlighted then
        object:setHighlightColor(r, g, b, a)
    end
    object:setHighlighted(highlighted, false)
end


---@param option unknown?
---@param highlight starlit.Action.HighlightParams
---@param testResult starlit.ActionTester.Result
---@return boolean success Whether a mouseover object highlight was added.
local function addMouseoverObjectHighlight(option, highlight, testResult)
    if highlight ~= nil then
        local highlightObject = testResult.objects[highlight.object].object
        if highlightObject then
            option.onHighlight = highlightObjectOnSelect
            option.onHighlightParams = {
                highlightObject,
                Colour.getRGBA(highlight.colour or defaultHighlightColour)
            }
            return true
        end
    end
    return false
end


---@param option unknown?
---@param context ISContextMenu
---@param highlighted boolean
---@param action starlit.ActionUI.ObjectAction
---@param fail starlit.ActionTester.Result
local function addTooltipOnSelect(option, context, highlighted, action, fail)
    if highlighted then
        option.toolTip = ActionUI.createTooltip(action.action, fail)
        if action.config.highlight ~= nil then
            local doHighlight = addMouseoverObjectHighlight(option, action.config.highlight, fail)
            if doHighlight then
                option:onHighlight(context, highlighted, unpack(option.onHighlightParams))
            end
        else
            option.onHighlight = nil
            option.onHighlightParams = nil
        end
    end
end


---@param context ISContextMenu
---@param testResult starlit.ActionTester.Result
---@param config starlit.Action.TooltipConfiguration
---@return unknown? option no typedef for this in umbrella grr
local function addActionOption(context, testResult, config)
    local state = ActionState.fromTestResult(testResult)
    local option = context:addOption(testResult.action.name, state, Actions.queueAction)

    if config.highlight ~= nil then
        addMouseoverObjectHighlight(option, config.highlight, testResult)
    end

    if config.getTooltipText ~= nil then
        local tooltip = ISWorldObjectContextMenu.addToolTip() --[[@as ISToolTip]]
        tooltip.name = testResult.action.name
        tooltip.description = config.getTooltipText(state)
        option.toolTip = tooltip
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


---@param character IsoGameCharacter
---@param objects IsoObject[]
---@return {[starlit.ActionUI.ObjectAction]: {successes: starlit.ActionTester.Result[], fails: starlit.ActionTester.Result[]}}
local function findActions(character, objects)
    local testResults = {}
    local tester = ActionTester.new(character)

    for i = 1, #objectActions do
        local objectAction = objectActions[i]
        local successes = {}
        local fails = {}

        -- if true, we test every object as the objectAs
        -- if false, we just do one test with all objects
        local testAllObjects = objectAction.config.objectAs ~= nil

        for j = 1, #objects do
            local forceParams = nil
            if testAllObjects then
                forceParams = {
                    objects = {
                        [objectAction.config.objectAs] = objects[j]
                    }
                }
            end


            local result = tester:test(
                objectAction.action,
                objects,
                forceParams
            )

            if result.success then
                table.insert(successes, result)
            else
                table.insert(fails, result)
            end

            if not testAllObjects then
                break
            end
        end


        if #successes > 0 or #fails > 0 then
            testResults[objectAction] = {
                successes = successes,
                fails = fails
            }
        end
    end

    return testResults
end


---@type Callback_OnFillWorldObjectContextMenu
local function addObjectActionOptions(playerNum, context, worldObjects, test)
    local testResults = findActions(
        getSpecificPlayer(playerNum),
        worldObjects[1]:getSquare():getLuaTileObjectList() --[[@as IsoObject[]]
    )

    for action, results in pairs(testResults) do
        local menu = context

        local showFails = not action.config.showFailConditions.noSuccesses or #results.successes == 0

        -- remove fails that don't meet the requirements for a tooltip
        local required = action.config.showFailConditions.required
        if required then
            -- loop backwards so we can remove elements safely
            for i = #results.fails, 1, -1  do
                local fail = results.fails[i]
                -- inner repeat loop lets break act like continue for the numeric loop
                -- this code is too complex without it
                repeat
                    if required.items then
                        -- pairs loop because in the future we should be able to specify subrequirements
                        --  e.g. item must pass type check but not durability check
                        for name, _ in pairs(required.items) do
                            local testResult = fail.items[name]
                            -- because we add successes in order, last slot success means full success
                            if testResult[#testResult].success then
                                table.remove(results.fails, i)
                                break
                            end
                        end
                    end

                    if required.objects then
                        for name, _ in pairs(required.objects) do
                            if not fail.objects[name].success then
                                table.remove(results.fails, i)
                                break
                            end
                        end
                    end

                    if required.predicates then
                        for name, _ in pairs(required.predicates) do
                            if fail.predicates[name] == false then
                                table.remove(results.fails, i)
                                break
                            end
                        end
                    end
                until true
            end
        end

        local totalNumber = #results.successes
        if showFails then
            totalNumber = totalNumber + #results.fails
        end

        if action.config.subMenu and totalNumber > 0 then
            local option = menu:getOptionFromName(action.config.subMenu)
            if option then
                assert(option.subOption ~= nil)
                menu = menu:getSubMenu(option.subOption)
            else
                menu = addSubMenu(menu, action.config.subMenu)
            end
        end

        local duplicatePolicy = action.config.duplicatePolicy

        if totalNumber > 1 and duplicatePolicy == "submenu" then
            menu = addSubMenu(menu, action.action.name)
        end

        local successes = results.successes
        if #successes > 0 then
            if #successes == 1 or duplicatePolicy == "hide" then
                addActionOption(menu, successes[1], action.config)
            else
                for i = 1, #successes do
                    addActionOption(menu, successes[i], action.config)
                end
            end
        end

        if showFails and #results.fails > 0 then
            if action.config.showFailConditions.onlyOne then
                results.fails = {results.fails[1]}
            end

            for i = 1, #results.fails do
                local fail = results.fails[i]
                local option = menu:addOption(action.action.name)
                option.notAvailable = true
                -- we delay creation of the tooltip until the player actually selects the option
                -- this honestly doesn't save as much performance as i hoped it would but it's still helpful
                option.onHighlight = addTooltipOnSelect
                option.onHighlightParams = {action, fail}
            end
        end
    end
end

Events.OnFillWorldObjectContextMenu.Add(addObjectActionOptions)


return ActionUI