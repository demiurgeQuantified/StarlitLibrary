local Action = require("Starlit/action/Action")
local log = require("Starlit/debug/StarlitLog")

local DEBUG = getDebug()


local ActionState = {}

---@class starlit.ActionState
---@field def starlit.Action
---@field items table<any, InventoryItem | InventoryItem[]>
---@field objects table<any, IsoObject>
---@field character IsoGameCharacter

---@alias starlit.ActionState.FailReasons {objects: {}, predicates: {}, items: {}}

---Creates an action state for a specific action.
---An action must be complete for an action state to be built for it.
---@param action starlit.Action The action.
---@param character IsoGameCharacter The character to perform the action.
---@param objects IsoObject[] Objects that may be used in the action. (e.g. all objects clicked by the player).
---@return starlit.ActionState | nil state The created state. Nil if the state could not be created.
---@return starlit.ActionState.FailReasons | nil failedRequirements Reasons why the state could not be created. Nil if the state was created.
---@nodiscard
function ActionState.tryBuildActionState(action, character, objects)
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

    -- TODO: being able to pass in a set of items that *must* be used would be useful
    --  e.g. disassemble action, this screwdriver that the player clicked on must be used as prop1
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
        items = {}
    }

    -- copy the table before changing it so that changes don't propagate out of the function
    objects = copyTable(objects)

    for name, def in pairs(action.requiredObjects) do
        ---@type {[string] : boolean} | nil
        local spriteLookup = nil
        if def.sprites then
            spriteLookup = {}
            for i = 1, #def.sprites do
                spriteLookup[def.sprites[i]] = true
            end
        end

        local matchFound = false
        for i = 1, #objects do
            local object = objects[i]
            if spriteLookup == nil or spriteLookup[object:getSprite():getName()] then
                local passedAll = true
                for k = 1, #def.predicates do
                    if not def.predicates[k]:evaluate(object) then
                        passedAll = false
                        break
                    end
                end

                if passedAll then
                    matchFound = true
                    table.remove(objects, i)
                    state.objects[name] = object
                    break
                end
            end
        end

        if not matchFound then
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


    -- list of items that have already been claimed by another requirement
    -- this is stored as an arraylist because it is more efficient to remove from another arraylist
    local claimedItems = ArrayList.new()

    local inventory = character:getInventory()
    for name, def in pairs(action.requiredItems) do
        ---@cast def starlit.Action.RequiredItem
        local items = {}
        local satisfied = false

        ---@type ArrayList
        local itemArray = nil
        if def.types then
            itemArray = ArrayList.new()
            for i = 1, #def.types do
                inventory:getAllTypeRecurse(def.types[i], itemArray)
            end
        elseif def.tags then
            itemArray = ArrayList.new()
            for i = 1, #def.tags do
                inventory:getAllTagRecurse(def.tags[i], itemArray)
            end
        else
            -- FIXME: this does not recurse
            itemArray = ArrayList.new(inventory:getItems())
        end

        itemArray:removeAll(claimedItems)

        local numItems = itemArray:size()
        if numItems < def.count then
            anyRequirementFailed = true
            table.insert(failedRequirements.items, name)
        else
            for j = 0, numItems - 1 do
                local item = itemArray:get(j)

                local passedAll = true
                for k = 1, #def.predicates do
                    if not def.predicates[k]:evaluate(item) then
                        passedAll = false
                        break
                    end
                end

                if passedAll then
                    table.insert(items, item)
                    if #items == def.count then
                        satisfied = true
                        break
                    end
                end
            end

            if not satisfied then
                anyRequirementFailed = true
                return table.insert(failedRequirements.items, name)
            else
                for i = 1, #items do
                    claimedItems:add(items[i])
                end

                if def.count == 1 then
                    state.items[name] = items[1]
                else
                    state.items[name] = items
                end
            end
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
    -- TODO: cheaper function that just checks the state still passes its conditions
    --  e.g. items still in inventory + all predicates pass
    local objects = {}
    for _, object in pairs(state.objects) do
        table.insert(objects, object)
    end
    return ActionState.tryBuildActionState(state.def, state.character, objects) ~= nil
end

return ActionState