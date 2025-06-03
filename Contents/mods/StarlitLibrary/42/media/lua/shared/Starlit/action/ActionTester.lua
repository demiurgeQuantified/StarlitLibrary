-- TODO: it is reasonable to cache the results of tests over the same tick
--  when adding an object action option using objectAs,
--  object tests could be ran up to N^2 times even though the results won't change
--  when considering multiple actions could be testing the same objects/items, it's obviously inefficient
--
--  maybe item tests could store the set of *all usable items* that met the criteria, and we find the 
--  subset of every set (creating them if they aren't already cached) specified by a requirement
--  this would be done with ArrayLists instead of Sets because they aren't exposed, which isn't that fast
--  but may still be faster than the alternative, given that it at least moves most of the calculations to java


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
--  complication is we need to work out what to return when an object wasn't specified
--  all false?

---@alias starlit.ActionTest.ItemResult {success: boolean, validType: boolean, predicates: {[any]: boolean}}
---@alias starlit.ActionTest.ObjectResult {success: boolean, predicates: {[any]: boolean}}
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

        for i = 1, #objects do
            local object = objects[i]
            local matches = true

            if claimedObjects[object] and not forcedObject then
                matches = false
            end

            for j = 1, #requirement.predicates do
                if not requirement.predicates[j]:evaluate(object) then
                    matches = false
                    break
                end
            end

            if matches then
                result.objects[name] = object
                claimedObjects[object] = true
                break
            end
        end

        if not result.objects[name] then
            result.success = false
            result.objects[name] = false
        end
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
            -- FIXME: we don't get detailed fail reasons for forced items anymore
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

        local matches = {}
        for i = 1, #items do
            -- break acts as continue in this scope
            repeat
                local item = items[i]

                if claimedItems[item] then
                    break
                end

                for j = 1, #requirement.predicates do
                    if not requirement.predicates[j]:evaluate(item) then
                        break
                    end
                end

                matches[#matches + 1] = item
            until true

            if #matches == requirement.count then
                break
            end
        end

        if #matches == requirement.count then
            result.items[name] = matches
            for i = 1, #matches do
                claimedItems[matches[i]] = true
            end
        else
            result.success = false
            result.items[name] = false
        end
    end

    -- TODO: for tooltips we could do a full check on the first applicable item/object,
    --  and then shortcircuiting checks afterwards

    return result
end


return ActionTester