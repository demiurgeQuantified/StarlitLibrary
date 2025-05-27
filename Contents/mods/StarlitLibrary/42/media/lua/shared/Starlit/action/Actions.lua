local Actions = {}

---@class starlit.ActionState
---@field def starlit.Action
---@field items table<any, InventoryItem | InventoryItem[]>
---@field object IsoObject
---@field character IsoGameCharacter

---@param action starlit.Action
---@param character IsoGameCharacter
---@param object IsoObject | nil
---@return starlit.ActionState | nil
function Actions.tryBuildActionState(action, character, object)
    -- TODO: if this fails, it would be ideal to return *why* the action isn't valid
    -- TODO: being able to pass in a set of items that *must* be used would be useful
    --  e.g. disassemble action, this screwdriver that the player clicked on must be used as prop1
    local state = {
        def = action,
        character = character,
        object = object,
        items = {}
    }

    if action.requiredObject then
        -- TODO: it may be more flexible to pass a list of objects, so we can e.g. pass all objects on a square
        --  to check if an action that targets a specific object is valid for that square
        if not object then
            return nil
        end

        if action.requiredObject.sprites then
            local sprite = object:getSprite():getName()
            local found = false
            for i = 1, #action.requiredObject.sprites do
                if sprite == action.requiredObject.sprites[i] then
                    found = true
                    break
                end
            end
            if not found then
                return nil
            end
        end

        for k = 1, #action.requiredObject.predicates do
            if not action.requiredObject.predicates[k](object) then
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
        if def._type == "types" then
            itemArray = ArrayList.new()
            for i = 1, #def.types do
                inventory:getAllType(def.types[i], itemArray)
            end
        elseif def._type == "tags" then
            itemArray = ArrayList.new()
            for i = 1, #def.tags do
                inventory:getAllTag(def.tags[i], itemArray)
            end
        elseif def._type == "predicates" then
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
function Actions.isActionStateStillValid(state)
    -- TODO: cheaper function that just checks the state still passes its conditions
    -- e.g. items still in inventory + all predicates pass
    return Actions.tryBuildActionState(state.def, state.character, state.object) ~= nil
end

---@param action starlit.Action
---@param character IsoGameCharacter
---@param object IsoObject | nil
function Actions.queueActionIfPossible(action, character, object)
    local state = Actions.tryBuildActionState(
        action,
        character,
        object
    )
    if not state then
        return
    end

    -- TODO: restructure so this runtime require isn't needed
    --  this function may want to be separated into a different module (rename this one to ActionStates?)
    --  Actions -> PrepareActionAction -> PerformActionAction -> Actions
    ISTimedActionQueue.add(require("Starlit/internal/PrepareActionAction").new(state))
end

return Actions