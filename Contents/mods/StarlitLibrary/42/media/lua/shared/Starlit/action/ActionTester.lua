-- TODO: it is reasonable to cache the results of tests over the same tick
--  when adding an object action option using objectAs,
--  object tests could be ran up to N^2 times even though the results won't change
--  when considering multiple actions could be testing the same objects/items, it's obviously inefficient


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
---@field items table<any, starlit.ActionTest.ItemResult[]>
---
---The objects that were picked for the action, by name of the object requirement.
---If the value is an ObjectTestResult or false, no object was picked.
---@field objects table<any, starlit.ActionTest.ObjectResult>
---
---The results of each predicate test by name.
---@field predicates table<any, boolean>


---@alias starlit.ActionTest.ItemResult {item: InventoryItem | nil, success: boolean, validType: boolean, predicates: {[any]: boolean}}
---@alias starlit.ActionTest.ObjectResult {object: IsoObject | nil, success: boolean, predicates: {[any]: boolean}}
---@alias starlit.ActionTest.ForceParams {objects: {[any]: IsoObject} | nil, items: {[any]: InventoryItem|InventoryItem[]} | nil}


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

-- #region ActionTester

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


---Tests if an action is valid.
---An action must be complete for an action state to be built for it.
---@param action starlit.Action The action.
---@param objects IsoObject[] Objects that may be used in the action. (e.g. all objects clicked by the player).
---@param forceParams starlit.ActionTest.ForceParams | nil Items and objects that must be used in the action. If they cannot be used, the function will return early. failedRequirements will only detail why these items were inappropriate.
---@return starlit.ActionTest.Result result The result of the test.
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

    ---@type starlit.ActionTest.Result
    local result = {
        action = action,
        character = self.character,
        items = {},
        objects = {},
        predicates = {},
        success = true
    }

    local requiredObjects = action.requiredObjects
    local requiredItems = action.requiredItems

    --- lookup table of items that have already been claimed by a requirement
    --- we don't just remove them from the list because it's too expensive lol
    ---@type table<InventoryItem, boolean>
    local claimedItems = {}

    ---@type table<IsoObject, boolean>
    local claimedObjects = {}

    for name, requirement in pairs(requiredObjects) do
        -- copy the upvalue to a local so we can change it later without propagating the change
        local objects = objects

        local forcedObject = forceParams and forceParams.objects and forceParams.objects[name]
        if forcedObject then
            -- override the object list with just the forced object
            objects = {forcedObject}
            claimedObjects[forcedObject] = true
        end

        local shortCircuit = false
        ---@type starlit.ActionTest.ObjectResult
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

            for j = 1, #requirement.predicates do
                if not requirement.predicates[j]:evaluate(object) then
                    matches = false
                    if shortCircuit then
                        break
                    end
                    testResult.predicates[j] = false
                elseif not shortCircuit then
                    testResult.predicates[j] = true
                end
            end

            if matches then
                -- construct a new test result with all conditions true
                testResult = {
                    object = object,
                    success = true,
                    predicates = {}
                }
                for j = 1, #requirement.predicates do
                    testResult.predicates[j] = true
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

    for i = 1, #action.predicates do
        if not action.predicates[i]:evaluate(self.character) then
            result.success = false
            result.predicates[i] = false
        else
            result.predicates[i] = true
        end
    end

    for name, requirement in pairs(requiredItems) do
        ---@type InventoryItem[]
        local items = nil

        local forcedItem = forceParams and forceParams.items and forceParams.items[name]
        if forcedItem then
            if type(forcedItem) == "table" then
                items = forcedItem
            else
                items = {forcedItem}
            end
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
            for i = 1, #requirement.types do
                local tagItems = self.itemsByTag[requirement.types[i]]
                if tagItems then
                    for j = 1, #tagItems do
                        items[#items + 1] = tagItems[j]
                    end
                end
            end
        else
            items = self.items
        end

        ---@type starlit.ActionTest.ItemResult[]
        local itemResults = {}
        for i = 1, requirement.count do
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
                end

                if claimedItems[item] then
                    break
                end

                for j = 1, #requirement.predicates do
                    if not requirement.predicates[j]:evaluate(item) then
                        if shortCircuit then
                            break
                        end
                        itemResult.predicates[j] = false
                        itemResult.success = false
                    else
                        itemResult.predicates[j] = true
                    end
                end

                if itemResult.success then
                    matchesFound = matchesFound + 1
                    -- if we found a match, we want to do a full test on the next one
                    --  so that we have full data for each item slot
                    shortCircuit = false
                else
                    shortCircuit = true
                end
            until true

            if matchesFound == requirement.count then
                break
            end
        end

        result.items[name] = itemResults
        for i = 1, matchesFound do
            claimedItems[itemResults[i].item] = true
        end

        if matchesFound ~= requirement.count then
            result.success = false
        end
    end

    return result
end


return ActionTester
-- #endregion