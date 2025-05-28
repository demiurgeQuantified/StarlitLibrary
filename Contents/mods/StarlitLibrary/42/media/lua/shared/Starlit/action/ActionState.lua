local Action = require("Starlit/action/Action")
local log = require("Starlit/debug/StarlitLog")

local DEBUG = getDebug()


local ActionState = {}

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

---@alias starlit.ActionState.FailReasons {objects: any[], predicates: integer[], items: any[], type: string}
---@alias starlit.ActionState.ForceParams {objects: {[any]: IsoObject} | nil, items: {[any]: InventoryItem|InventoryItem[]} | nil}

---Checks a list of objects against an object requirement.
---To check only one object, pass a table with that object as the only element. (The cost of constructing a table is far less than the function overhead that would be incurred if this delegated each check to a single-check function.)
---@param requirement starlit.Action.RequiredObject The object requirement to check against.
---@param objects IsoObject[] Objects to check. The first found match (if any) will be removed from the list.
---@return IsoObject | nil match The first matching object found, or nil if there was no match.
function ActionState.findObjectMatch(requirement, objects)
    for i = 1, #objects do
        local object = objects[i]
        for k = 1, #requirement.predicates do
            if not requirement.predicates[k]:evaluate(object) then
                return nil
            end
        end
        table.remove(objects, i)
        return object
    end
end

---Checks all items in a container against an object requirement.
---@param requirement starlit.Action.RequiredItem The item requirement to check against.
---@param itemArray ArrayList List of items to check.
---@return InventoryItem | InventoryItem[] | nil
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
---@return starlit.ActionState.FailReasons | nil failedRequirements Reasons why the state could not be created. Nil if the state was created.
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
                if object:isExistInTheWorld()
                    and ActionState.findObjectMatch(requiredObjects[name], {object}) ~= nil then
                    -- remove the requirement so that it isn't checked later
                    requiredObjects[name] = nil
                    state.objects[name] = object
                    -- FIXME: remove object from objects if present or it could be used for another requirement
                else
                    anyRequirementFailed = true
                    table.insert(failedRequirements.objects, name)
                end
            end
        end

        if forceParams.items then
            for name, item in pairs(forceParams.items) do
                local itemList = ArrayList.new()
                if type(item) == "table" then
                    for i = 1, #item do
                        itemList:add(item[i])
                    end
                else
                    itemList:add(item)
                end

                if ActionState.findItemMatch(requiredItems[name], itemList) ~= nil then
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
                    table.insert(failedRequirements.items, name)
                end
            end
        end

        if anyRequirementFailed then
            -- return early if any forcedparam did not match
            return nil, failedRequirements
        end
    end

    failedRequirements.type = "regular"

    -- copy the table before changing it so that changes don't propagate out of the function
    objects = copyTable(objects)

    for name, requirement in pairs(requiredObjects) do
        local object = ActionState.findObjectMatch(requirement, objects)
        if object then
            state.objects[name] = object
        else
            anyRequirementFailed = true
            table.insert(failedRequirements.objects, name)
        end
    end

    for i = 1, #action.predicates do
        if not action.predicates[i]:evaluate(character) then
            anyRequirementFailed = true
            table.insert(failedRequirements.predicates, i)
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
            table.insert(failedRequirements.items, name)
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