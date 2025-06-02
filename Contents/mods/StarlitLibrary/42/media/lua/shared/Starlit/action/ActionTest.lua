-- TODO: it is reasonable to cache the results of tests over the same tick
-- when adding an object action option using objectAs,
-- object tests could be ran up to N^2 times even though the results won't change
-- when considering multiple actions could be testing the same objects/items, it's obviously inefficient


---Result from an action test.
---@class starlit.ActionTest.Result
---
---Whether the test was a success.
---@field success boolean
---
---The action that was tested.
---@field action starlit.Action
---
---The character that was tested.
---@field character IsoGameCharacter
---
---The items that were picked for the action, by name of the item requirement.
---If the value is a ItemTestResult or false, no item was picked.
---@field items table<any, InventoryItem[] | starlit.ActionTest.ItemResult[] | false>
---
---The objects that were picked for the action, by name of the object requirement.
---If the value is an ObjectTestResult or false, no object was picked.
---@field objects table<any, IsoObject | starlit.ActionTest.ObjectResult | false>
---
---The results of each predicate test by name.
---@field predicates table<any, boolean>


-- TODO: add testedItem/testedObject fields to these, always return a result even when successful
--  this would allow us to e.g. highlight an object that partially matched

---@alias starlit.ActionTest.ItemResult {success: boolean, validType: boolean, predicates: {[any]: boolean}}
---@alias starlit.ActionTest.ObjectResult {success: boolean, predicates: {[any]: boolean}}
---@alias starlit.ActionTest.ForceParams {objects: {[any]: IsoObject} | nil, items: {[any]: InventoryItem|InventoryItem[]} | nil}


local Action = require("Starlit/action/Action")
local log = require("Starlit/debug/StarlitLog")

local DEBUG = getDebug()


local ActionTest = {}


---Checks a list of objects against an object requirement.
---To check only one object, pass a table with that object as the only element.
---@param requirement starlit.Action.RequiredObject The object requirement to check against.
---@param objects IsoObject[] Objects to check. The first found match (if any) will be removed from the list.
---@return IsoObject | nil match The first matching object found, or nil if there was no match.
function ActionTest.findObjectMatch(requirement, objects)
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


---Checks all items in a container against an object requirement.
---@param requirement starlit.Action.RequiredItem The item requirement to check against.
---@param itemArray ArrayList List of items to check.
---@return InventoryItem[] | nil item The first matching items found, if any.
---@nodiscard
function ActionTest.findItemMatch(requirement, itemArray)
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

        return items
    end
end


---Tests if an object passes an object requirement.
---@param requirement starlit.Action.RequiredObject The object requirement.
---@param object IsoObject The object.
---@return starlit.ActionTest.ObjectResult result Test result.
---@nodiscard
function ActionTest.testObjectDetailed(requirement, object)
    local result = {
        predicates = {},
        success = true,
    }

    for i = 1, #requirement.predicates do
        local passed = requirement.predicates[i]:evaluate(object)
        result.predicates[i] = passed
        if not passed then
            result.success = false
        end
    end

    return result
end


---Tests if an item passes an item requirement.
---@param requirement starlit.Action.RequiredItem The item requirement.
---@param item InventoryItem The item.
---@return starlit.ActionTest.ItemResult result Test result.
---@nodiscard
function ActionTest.testItemDetailed(requirement, item)
    local result = {
        validType = false,
        predicates = {},
        success = true
    }

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
        result.success = false
    end

    -- check that it passes all predicates
    for i = 1, #requirement.predicates do
        local passed = requirement.predicates[i]:evaluate(item)
        result.predicates[i] = passed
        if not passed then
            result.success = false
        end
    end

    return result
end


---Tests if an action is valid.
---An action must be complete for an action state to be built for it.
---@param action starlit.Action The action.
---@param character IsoGameCharacter The character to perform the action.
---@param objects IsoObject[] Objects that may be used in the action. (e.g. all objects clicked by the player).
---@param forceParams starlit.ActionTest.ForceParams | nil Items and objects that must be used in the action. If they cannot be used, the function will return early. failedRequirements will only detail why these items were inappropriate.
---@return starlit.ActionTest.Result result The result of the test.
---@nodiscard
function ActionTest.test(action, character, objects, forceParams)
    if not Action.isComplete(action) then
        if DEBUG then
            -- TODO: print this error even outside of debug mode
            --  this is disabled currently because the error will always blame starlit library,
            --  when it's the mod that created the action at fault.
            --  at the time of action creation, we could look up the callstack to see which mod is creating it
            log("Attempting to create state for action %s, but it is incomplete.", "error", action.name)
        end
        return nil
    end

    ---@type starlit.ActionTest.Result
    local result = {
        action = action,
        character = character,
        items = {},
        objects = {},
        predicates = {},
        success = true
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

        if forceParams.objects then
            for name, object in pairs(forceParams.objects) do
                -- remove from objects if present so that it isn't used for another condition
                for i = 1, #objects do
                    if objects[i] == object then
                        table.remove(objects, i)
                        break
                    end
                end
                -- we don't assume passed objects exist as they might be coming from ActionState.stillValid
                if object:isExistInTheWorld() then
                    local testResult = ActionTest.testObjectDetailed(requiredObjects[name], object)
                    if testResult.success then
                        result.objects[name] = object
                    else
                        result.success = false
                        result.objects[name] = testResult
                    end

                    -- remove the requirement so that it isn't double checked later
                    requiredObjects[name] = nil
                end
            end
        end

        if forceParams.items then
            for name, item in pairs(forceParams.items) do
                -- make sure the forced items won't be used for another requirement
                if type(item) == "table" then
                    for i = 1, #item do
                        claimedItems:add(item[i])
                    end
                else
                    claimedItems:add(item)
                end

                -- FIXME: this doesn't support a table of items
                local testResult = ActionTest.testItemDetailed(requiredItems[name], item)

                if testResult.success then
                    result.items[name] = {item}
                else
                    result.success = false
                    result.items[name] = {testResult}
                end

                -- remove the requirement so that it isn't double checked later
                requiredItems[name] = nil
            end
        end
    end

    for name, requirement in pairs(requiredObjects) do
        local object = ActionTest.findObjectMatch(requirement, objects)
        if object then
            result.objects[name] = object
        else
            result.success = false
            result.objects[name] = false
        end
    end

    for i = 1, #action.predicates do
        if not action.predicates[i]:evaluate(character) then
            result.success = false
            result.predicates[i] = false
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

        local match = ActionTest.findItemMatch(requirement, items)
        if match then
            result.items[name] = match
            -- mark returned items as claimed
            for i = 1, #match do
                claimedItems:add(match[i])
            end
        else
            result.success = false
            result.items[name] = false
        end
    end

    return result
end


return ActionTest