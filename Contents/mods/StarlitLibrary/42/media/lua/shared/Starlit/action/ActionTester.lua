-- TODO: it is reasonable to cache the results of tests over the same tick
--  when adding an object action option using objectAs,
--  object tests could be ran up to N^2 times even though the results won't change
--  when considering multiple actions could be testing the same objects/items, it's obviously inefficient


---Result from an action test.
---@class starlit.ActionTester.Result
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
---The results of each item requirement, by name of the item requirement.
---@field items table<any, starlit.ActionTester.ItemResult[]>
---
---The results of each object requirement, by name of the object requirement.
---@field objects table<any, starlit.ActionTester.ObjectResult>
---
---The results of each predicate test by name.
---@field predicates table<any, boolean>
---
---The results of each skill check by the Perk tested.
---@field skills table<Perk, boolean>


---@alias starlit.ActionTester.ItemResult {item: InventoryItem | nil, success: boolean, validType: boolean, predicates: {[any]: boolean}}
---@alias starlit.ActionTester.ObjectResult {object: IsoObject | nil, success: boolean, predicates: {[any]: boolean}}
---@alias starlit.ActionTester.ForceParams {objects: {[any]: IsoObject} | nil, items: {[any]: InventoryItem[]} | nil}


local Action = require("Starlit/action/Action")
local log = require("Starlit/debug/StarlitLog")

local DEBUG = getDebug()


---@param container ItemContainer
local function getAllItemsInContainerRecurse(container)
    local items = table.newarray()

    ---@type ItemContainer[]
    local containers = {container}
    while #containers > 0 do
        local container = containers[#containers]
        containers[#containers] = nil

        local containedItems = container:getItems()
        for i = 0, containedItems:size() - 1 do
            local item = containedItems:get(i)
            items[#items + 1] = item
            if instanceof(item, "InventoryContainer") then
                ---@cast item InventoryContainer
                containers[#containers + 1] = item:getInventory()
            end
        end
    end

    return items
end


---@param items InventoryItem[]
---@return table<string, InventoryItem[]>
local function buildItemTypeMap(items)
    ---@type table<string, InventoryItem[]>
    local typeMap = {}

    for i = 1, #items do
        local item = items[i]
        local type = item:getFullType()
        local typeList = typeMap[type]
        if not typeList then
            typeList = table.newarray()
            typeMap[type] = typeList
        end
        typeList[#typeList + 1] = item
    end

    return typeMap
end


---@param typeMap table<string, InventoryItem[]>
---@return table<string, InventoryItem[]>
local function buildItemTagMap(typeMap)
    ---@type table<string, InventoryItem[]>
    local tagMap = {}

    for _, items in pairs(typeMap) do
        local tags = items[1]:getTags()
        for i = 0, tags:size() - 1 do
            local tag = tags:get(i)
            local tagList = tagMap[tag]
            if tagList then
                for j = 1, #items do
                    tagList[#tagList + 1] = items[j]
                end
            else
                tagMap[tag] = table.newarray(items)
            end
        end
    end

    return tagMap
end


---Responsible for testing if a character can perform an action.
---ActionTester objects should have short lifetimes, generally within the function that creates them.
---They utilise heavy caching, and if the state of the game changes, this cache will become inaccurate.
---For this reason, you should only reuse an ActionTester object when testing actions in bulk all at once.
---If there's a risk that the state of the objects, items, or the character's inventory will change before
---the next test, don't cache it!
---@class starlit.ActionTester
---@field character IsoGameCharacter The character to perform tests for.
---@field items InventoryItem[] All of the items in the character's inventory.
---@field itemsByType table<string, InventoryItem[]> Map of every item in the character's inventory by its full type.
---@field itemsByTag table<string, InventoryItem[]> Map of every item in the character's inventory that has each tag.
local ActionTester = {}
ActionTester.__index = ActionTester

-- #region private


---@param requiredObjects table<any, starlit.Action.RequiredObject>
---@param result starlit.ActionTester.Result
---@param objects IsoObject[]
---@param forcedObjects table<any, IsoObject> | nil
function ActionTester:_testObjectRequirements(requiredObjects, result, objects, forcedObjects)
    ---@type table<IsoObject, boolean>
    local claimedObjects = {}

    if forcedObjects then
        for _, object in pairs(forcedObjects) do
            claimedObjects[object] = true
        end
    end

    for name, requirement in pairs(requiredObjects) do
        -- copy the argument to a local so we can change it later without propagating the change to later iterations
        local objects = objects

        local forcedObject = forcedObjects and forcedObjects[name] --[[@as IsoObject | nil]]
        if forcedObject then
            -- override the object list with just the forced object
            objects = {forcedObject}
        end

        local shortCircuit = false
        ---@type starlit.ActionTester.ObjectResult
        local testResult = {
            object = objects[1],
            success = false,
            predicates = {}
        }

        for i = 1, #objects do
            local object = objects[i]
            local matches = true

            if claimedObjects[object] and not forcedObject then
                matches = false
            end

            for name, predicate in pairs(requirement.predicates) do
                if not predicate:evaluate(object) then
                    matches = false
                    if shortCircuit then
                        break
                    end
                    testResult.predicates[name] = false
                elseif not shortCircuit then
                    testResult.predicates[name] = true
                end
            end

            if matches then
                -- construct a new test result with all conditions true
                testResult = {
                    object = object,
                    success = true,
                    predicates = {}
                }
                for name, _ in pairs(requirement.predicates) do
                    testResult.predicates[name] = true
                end

                claimedObjects[object] = true
                break
            end

            -- after one run, we start short circuiting
            -- we don't want to build detailed fail data for every single object
            shortCircuit = true
        end

        if not testResult.success then
            result.success = false
        end
        result.objects[name] = testResult
    end
end


---@param requiredItems table<any, starlit.Action.RequiredItem>
---@param result starlit.ActionTester.Result
---@param forcedItems table<any, InventoryItem[]> | nil
function ActionTester:_testItemRequirements(requiredItems, result, forcedItems)
    ---@type {[InventoryItem]: boolean}
    local claimedItems = {}

    if forcedItems then
        for _, items in pairs(forcedItems) do
            for i = 1, #items do
                claimedItems[items[i]] = true
            end
        end
    end

    for name, requirement in pairs(requiredItems) do
        ---@type InventoryItem[]
        local items = nil

        local forcedItem = forcedItems and forcedItems[name]
        if forcedItem then
            items = forcedItem
        elseif requirement.types then
            items = table.newarray()
            for i = 1, #requirement.types do
                local typeItems = self.itemsByType[requirement.types[i]]
                if typeItems then
                    for j = 1, #typeItems do
                        items[#items + 1] = typeItems[j]
                    end
                end
            end
        elseif requirement.tags then
            items = table.newarray()
            for i = 1, #requirement.tags do
                local tagItems = self.itemsByTag[requirement.tags[i]]
                if tagItems then
                    for j = 1, #tagItems do
                        items[#items + 1] = tagItems[j]
                    end
                end
            end
        else
            items = self.items
        end

        local byUses = requirement.uses > 0
        local matchesNeeded = byUses and requirement.uses or requirement.count

        ---@type starlit.ActionTester.ItemResult[]
        local itemResults = {}
        for i = 1, matchesNeeded do
            itemResults[i] = {
                item = nil,
                success = false,
                predicates = {},
                validType = false,
            }
        end

        local matchesFound = 0
        for i = 1, #items do
            local item = items[i]
            local itemResult = itemResults[matchesFound + 1]
            itemResult.validType = true
            itemResult.item = item
            itemResult.success = true

            local shortCircuit = false

            -- break acts as continue in this scope
            repeat
                -- if the item isn't forced, then it is already the right type/tags
                if forcedItem then
                    if requirement.tags then
                        itemResult.validType = false
                        for j = 1, #requirement.tags do
                            if item:hasTag(requirement.tags[j]) then
                                itemResult.validType = true
                                break
                            end
                        end
                    elseif requirement.types then
                        itemResult.validType = false
                        local type = item:getFullType()
                        -- it would be optimal to build a lookup table of these in cases where there are multiple forced items
                        for j = 1, #requirement.types do
                            if type == requirement.types[j] then
                                itemResult.validType = true
                                break
                            end
                        end
                    end

                    if not itemResult.validType then
                        -- we don't want to do further tests on items that aren't the right type,
                        --  even if we aren't short circuiting generally
                        break
                    end
                elseif claimedItems[item] then
                    -- elseif because forced items will always be claimed
                    break
                end

                for name, predicate in pairs(requirement.predicates) do
                    if not predicate:evaluate(item) then
                        itemResult.success = false
                        if shortCircuit then
                            break
                        end
                        itemResult.predicates[name] = false
                    else
                        itemResult.predicates[name] = true
                    end
                end

                local uses
                if byUses then
                    uses = item:getCurrentUses()
                    if uses == 0 then
                        itemResult.success = false
                        if shortCircuit then
                            break
                        end
                    end
                end

                if itemResult.success then
                    if byUses then
                        local remainingUsesNeeded = requirement.uses - matchesFound
                        if uses > remainingUsesNeeded then
                            uses = remainingUsesNeeded
                        end
                        matchesFound = matchesFound + 1
                        for _ = 2, uses do
                            copyTable(itemResults[matchesFound + 1], itemResult)
                            matchesFound = matchesFound + 1
                        end
                    else
                        matchesFound = matchesFound + 1
                    end
                    -- if we found a match, we want to do a full test on the next one
                    --  so that we have full data for each item slot
                    shortCircuit = false
                else
                    shortCircuit = true
                end
            until true

            if matchesFound == matchesNeeded then
                break
            end
        end

        result.items[name] = itemResults
        for i = 1, matchesFound do
            claimedItems[itemResults[i].item] = true
        end

        if matchesFound ~= matchesNeeded then
            result.success = false
        end
    end
end


-- #endregion
-- #region public


---Tests if an action is valid.
---An action must be complete for an action state to be built for it.
---@param action starlit.Action The action.
---@param objects IsoObject[] Objects that may be used in the action. (e.g. all objects clicked by the player).
---@param forceParams starlit.ActionTester.ForceParams | nil Items and objects that must be used in the action. If they cannot be used, the function will return early. failedRequirements will only detail why these items were inappropriate.
---@return starlit.ActionTester.Result result The result of the test.
---@nodiscard
function ActionTester:test(action, objects, forceParams)
    if not Action.isComplete(action) then
        if DEBUG then
            -- TODO: print this error even outside of debug mode
            --  this is disabled currently because the error will always blame starlit library,
            --  when it's the mod that created the action at fault.
            --  at the time of action creation, we could look up the callstack to see which mod is creating it
            log("Attempting to test for action %s, but it is incomplete.", "error", action.name)
        end
        return nil
    end

    ---@type starlit.ActionTester.Result
    local result = {
        action = action,
        character = self.character,
        items = {},
        objects = {},
        predicates = {},
        skills = {},
        success = true
    }

    self:_testObjectRequirements(
        action.requiredObjects,
        result,
        objects,
        forceParams and forceParams.objects or nil
    )

    for name, predicate in pairs(action.predicates) do
        if predicate:evaluate(self.character) then
            result.predicates[name] = true
        else
            result.success = false
            result.predicates[name] = false
        end
    end

    for perk, minLevel in pairs(action.requiredSkills) do
        if self.character:getPerkLevel(perk) >= minLevel then
            result.skills[perk] = true
        else
            result.success = false
            result.skills[perk] = false
        end
    end

    self:_testItemRequirements(
        action.requiredItems,
        result,
        forceParams and forceParams.items or nil
    )

    return result
end


---Creates an ActionTester for a specific character.
---@param character IsoGameCharacter The character.
---@return starlit.ActionTester tester
---@nodiscard
function ActionTester.new(character)
    local o = {
        character = character,
        items = getAllItemsInContainerRecurse(character:getInventory())
    }
    o.itemsByType = buildItemTypeMap(o.items)
    o.itemsByTag = buildItemTagMap(o.itemsByType)
    setmetatable(o, ActionTester)

    return o
end

return ActionTester
-- #endregion