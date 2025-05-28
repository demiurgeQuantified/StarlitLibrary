local Action = require("Starlit/action/Action")
local log = require("Starlit/debug/StarlitLog")

local DEBUG = getDebug()


local ActionState = {}

---@class starlit.ActionState
---@field def starlit.Action
---@field items table<any, InventoryItem | InventoryItem[]>
---@field objects table<any, IsoObject>
---@field character IsoGameCharacter

---@param action starlit.Action
---@param character IsoGameCharacter
---@param objects IsoObject[]
---@return starlit.ActionState | nil
function ActionState.tryBuildActionState(action, character, objects)
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

    -- TODO: if this fails, it would be ideal to return *why* the action isn't valid
    -- TODO: being able to pass in a set of items that *must* be used would be useful
    --  e.g. disassemble action, this screwdriver that the player clicked on must be used as prop1
    local state = {
        def = action,
        character = character,
        objects = {},
        items = {}
    }

    -- this could probably be cached at time of action creation to prevent wasteful recalculations
    local numRequiredObjects = 0
    for _, _ in pairs(action.requiredObjects) do
        numRequiredObjects = numRequiredObjects + 1
    end

    if #objects < numRequiredObjects then
        return nil
    end

    -- copy the table before changing it so that changes don't propagate out of the function
    if numRequiredObjects > 0 then
        objects = copyTable(objects)

        for name, def in pairs(action.requiredObjects) do
            local matchFound = false
            for i = 1, #objects do
                local object = objects[i]

                local spriteAllowed = true
                if def.sprites then
                    local sprite = object:getSprite():getName()
                    local found = false
                    for j = 1, #def.sprites do
                        if sprite == def.sprites[j] then
                            found = true
                            break
                        end
                    end
                    if not found then
                        spriteAllowed = false
                    end
                end

                -- true if the sprite matched the list, or there is no sprite list
                if spriteAllowed then
                    local passedAll = true
                    for k = 1, #def.predicates do
                        if not def.predicates[k](object) then
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
                return nil
            end
        end
    end

    for i = 1, #action.predicates do
        if not action.predicates[i](character) then
            return nil
        end
    end

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
            return nil
        end

        for j = 0, numItems - 1 do
            local item = itemArray:get(j)

            local passedAll = true
            for k = 1, #def.predicates do
                if not def.predicates[k](item) then
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
            return nil
        end

        for i = 1, #items do
            claimedItems:add(items[i])
        end

        if def.count == 1 then
            state.items[name] = items[1]
        else
            state.items[name] = items
        end
    end

    return state
end

---@param state starlit.ActionState
---@return boolean
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