local Action = require("Starlit/action/Action")
local log = require("Starlit/debug/StarlitLog")

local DEBUG = getDebug()


-- TODO: it is reasonable to cache the results of tests over the same tick
-- when adding an object action option using objectAs,
-- object tests could be ran up to N^2 times even though the results won't change
-- when considering multiple actions could be testing the same objects/items, it's obviously inefficient


local ActionState = {}

-- TODO: merge ActionFailReasons and ActionState into TestResult, add 'success' field
-- if a requirement succeeds, set the requirement to the passing object, otherwise set it to false orfail details
-- success field is only true if all requirements passed

---State of a specific action attempt.
---Where an Action defines the kinds of items and objects needed, an ActionState contains the specific items and objects being used in an action.
---@class starlit.ActionState
---
---The Action this ActionState corresponds to.
---@field def starlit.Action
---
---The items used in the action. Keys correspond to requiredItems.
---Values will be a table if the count of the requiredItem is more than 1. Otherwise they are InventoryItems.
---@field items table<any, InventoryItem | InventoryItem[]>
---
---The objects used in the action. Keys correspond to the action's requiredObjects.
---@field objects table<any, IsoObject>
---
---The character performing the action.
---@field character IsoGameCharacter

---@alias starlit.ActionState.ItemFailReasons {validType: boolean, predicates: {[any]: boolean}}
---@alias starlit.ActionState.ObjectFailReasons {predicates: {[any]: boolean}}
---@alias starlit.ActionState.ActionFailReasons {objects: {[any]: starlit.ActionState.ObjectFailReasons | boolean}, predicates: integer[], items: {[any]: starlit.ActionState.ItemFailReasons | boolean}, type: string}
---@alias starlit.ActionState.ForceParams {objects: {[any]: IsoObject} | nil, items: {[any]: InventoryItem|InventoryItem[]} | nil}

---Checks a list of objects against an object requirement.
---To check only one object, pass a table with that object as the only element.
---@param requirement starlit.Action.RequiredObject The object requirement to check against.
---@param objects IsoObject[] Objects to check. The first found match (if any) will be removed from the list.
---@return IsoObject | nil match The first matching object found, or nil if there was no match.
function ActionState.findObjectMatch(requirement, objects)
    for i = 1, #objects do
        local object = objects[i]
        for j = 1, #requirement.predicates do
            if not requirement.predicates[j]:evaluate(object) then
                return nil
            end
        end
        table.remove(objects, i)
        return object
    end
end


---@param requirement starlit.Action.RequiredObject
---@param object IsoObject
---@return boolean pass, starlit.ActionState.ObjectFailReasons details
function ActionState.testObjectDetailed(requirement, object)
    local result = {
        predicates = {}
    }
    local noFailures = true

    for i = 1, #requirement.predicates do
        local passed = requirement.predicates[i]:evaluate(object)
        result.predicates[i] = passed
        if not passed then
            noFailures = false
        end
    end

    return noFailures, result
end


---@param requirement starlit.Action.RequiredItem
---@param item InventoryItem
---@return boolean pass, starlit.ActionState.ItemFailReasons details
function ActionState.testItemDetailed(requirement, item)
    local result = {
        validType = false,
        predicates = {}
    }
    local noFailures = true

    -- check if the item type is valid
    if requirement.types then
        local type = item:getFullType()
        for i = 1, #requirement.types do
            if type == requirement.types[i] then
                result.validType = true
                break
            end
        end
    elseif requirement.tags then
        for i = 1, #requirement.tags do
            if item:hasTag(requirement.tags[i]) then
                result.validType = true
                break
            end
        end
    else
        result.validType = true
    end

    if not result.validType then
        noFailures = false
    end

    -- check that it passes all predicates
    for i = 1, #requirement.predicates do
        local passed = requirement.predicates[i]:evaluate(item)
        result.predicates[i] = passed
        if not passed then
            noFailures = false
        end
    end

    return noFailures, result
end


---Checks all items in a container against an object requirement.
---@param requirement starlit.Action.RequiredItem The item requirement to check against.
---@param itemArray ArrayList List of items to check.
---@return InventoryItem | InventoryItem[] | nil item The first matching item found, if any.
---@nodiscard
function ActionState.findItemMatch(requirement, itemArray)
    ---@type InventoryItem[]
    local items = {}
    local satisfied = false

    -- FIXME: an issue is possible where overlapping requirements may cause an unexpected failure
    --  a requirement that is satisfied by a superset of another could claim every item it needs
    --  the other requirement would fail, even though the player *does* have a valid set of items
    --  the solution to this would be to mark every item that could fulfil a requirement
    --  and resolve which requirement claims each afterwards, prioritising non-overlapping items
    --  example:
    --   1 item of any kind required
    --   1 screwdriver required
    --  the first requirement could claim my only screwdriver, and then the screwdriver requirement fails,
    --  even though i have plenty of other items!
    itemArray = ArrayList.new(itemArray)

    local numItems = itemArray:size()
    if numItems < requirement.count then
        return nil
    else
        for j = 0, numItems - 1 do
            local item = itemArray:get(j)

            local passedAll = true
            for k = 1, #requirement.predicates do
                if not requirement.predicates[k]:evaluate(item) then
                    passedAll = false
                    break
                end
            end

            if passedAll then
                table.insert(items, item)
                if #items == requirement.count then
                    satisfied = true
                    break
                end
            end
        end

        if not satisfied then
            return nil
        end

        if #items == 1 then
            return items[1]
        end

        return items
    end
end


---Creates an action state for a specific action.
---An action must be complete for an action state to be built for it.
---@param action starlit.Action The action.
---@param character IsoGameCharacter The character to perform the action.
---@param objects IsoObject[] Objects that may be used in the action. (e.g. all objects clicked by the player).
---@param forceParams starlit.ActionState.ForceParams | nil Items and objects that must be used in the action. If they cannot be used, the function will return early. failedRequirements will only detail why these items were inappropriate.
---@return starlit.ActionState | nil state The created state. Nil if the state could not be created.
---@return starlit.ActionState.ActionFailReasons | nil failedRequirements Reasons why the state could not be created. Nil if the state was created.
---@nodiscard
function ActionState.tryBuildActionState(action, character, objects, forceParams)
    if not Action.isComplete(action) then
        if DEBUG then
            -- TODO: print this error even outside of debug mode
            --  this is disabled currently because the error will always blame starlit library,
            --  when it's the mod that created the action at fault.
            --  at the time of action creation, we could look up the callstack to see which mod is creating it
            log("Attempting to create state for action %s, but it is incomplete.", "error", action.name)
        end
        return nil, nil
    end

    local state = {
        def = action,
        character = character,
        objects = {},
        items = {}
    }

    local anyRequirementFailed = false
    local failedRequirements = {
        objects = {},
        predicates = {},
        items = {},
        type = "forced"
    }

    local requiredObjects = action.requiredObjects
    local requiredItems = action.requiredItems

    -- list of items that have already been claimed by another requirement
    -- this is stored as an arraylist because it is more efficient to remove from another arraylist
    local claimedItems = ArrayList.new()

    -- copy the table before changing it so that changes don't propagate out of the function
    objects = copyTable(objects)

    -- check forced params first, if they don't match we can return early
    if forceParams then
        -- copy before modifying so we don't propagate changes to the action itself
        requiredObjects = copyTable(action.requiredObjects)
        requiredItems = copyTable(action.requiredItems)

        -- IDEA: we could return more detailed fail info for these
        --  so we could have a tooltip say 'you can't use this hammer because it's broken'
        --  instead of 'you need a hammer'

        if forceParams.objects then
            for name, object in pairs(forceParams.objects) do
                -- we don't assume passed objects exist as they might be coming from isActionStateStillValid
                if object:isExistInTheWorld() then
                    local pass, failDetails = ActionState.testObjectDetailed(requiredObjects[name], object)
                    if pass then
                        -- remove the requirement so that it isn't checked later
                        requiredObjects[name] = nil
                        state.objects[name] = object

                        -- remove from objects if present so that it isn't used for another condition
                        for i = 1, #objects do
                            if objects[i] == object then
                                table.remove(objects, i)
                                break
                            end
                        end
                    else
                        anyRequirementFailed = true
                        failedRequirements.objects[name] = failDetails
                    end
                end
            end
        end

        if forceParams.items then
            for name, item in pairs(forceParams.items) do
                -- FIXME: this doesn't support a table of items
                local pass, failDetails = ActionState.testItemDetailed(requiredItems[name], item)
                if pass then
                    requiredItems[name] = nil
                    state.items[name] = item
                    if type(item) == "table" then
                        for i = 1, #item do
                            claimedItems:add(item[i])
                        end
                    else
                        claimedItems:add(item)
                    end
                else
                    anyRequirementFailed = true
                    failedRequirements.items[name] = failDetails
                end
            end
        end

        if anyRequirementFailed then
            -- return early if any forcedparam did not match
            return nil, failedRequirements
        end
    end

    failedRequirements.type = "regular"

    for name, requirement in pairs(requiredObjects) do
        local object = ActionState.findObjectMatch(requirement, objects)
        if object then
            state.objects[name] = object
        else
            anyRequirementFailed = true
            failedRequirements.objects[name] = false
        end
    end

    for i = 1, #action.predicates do
        if not action.predicates[i]:evaluate(character) then
            anyRequirementFailed = true
            failedRequirements.predicates[i] = false
        end
    end

    local inventory = character:getInventory()
    for name, requirement in pairs(requiredItems) do
        ---@type ArrayList
        local items = nil
        if requirement.types then
            items = ArrayList.new()
            for i = 1, #requirement.types do
                inventory:getAllTypeRecurse(requirement.types[i], items)
            end
        elseif requirement.tags then
            items = ArrayList.new()
            for i = 1, #requirement.tags do
                inventory:getAllTagRecurse(requirement.tags[i], items)
            end
        else
            -- FIXME: this does not recurse
            items = ArrayList.new(inventory:getItems())
        end
        items:removeAll(claimedItems)

        local match = ActionState.findItemMatch(requirement, items)
        if match then
            state.items[name] = match
            -- mark returned items as claimed
            if type(match) == "table" then
                for i = 1, #match do
                    claimedItems:add(match[i])
                end
            else
                claimedItems:add(match)
            end
        else
            anyRequirementFailed = true
            failedRequirements.items[name] = false
        end
    end

    if anyRequirementFailed then
        return nil, failedRequirements
    end

    return state
end

---Checks if the conditions of an action state are still met.
---@param state starlit.ActionState The state to check.
---@return boolean valid Whether the state is still valid.
---@nodiscard
function ActionState.isActionStateStillValid(state)
    return ActionState.tryBuildActionState(
        state.def,
        state.character,
        {},
        {
            objects = state.objects,
            items = state.items
        })
        ~= nil
end

return ActionState