local SelfMergeTable = require("Starlit/utils/SelfMergeTable")


local pass = function() end


---Predicate container class.
---@class starlit.Action.Predicate<T>
---@overload fun(other:self):self
---
---Evaluator function for the predicate.
---@field evaluate fun(self:starlit.Action.Predicate, obj:T):boolean
---
---Translated string to use as the description of the predicate in UI elements.
---@field description string


---RequiredItem args.
---This is the same as RequiredItem, but fields are marked as nullable to avoid the type checker reporting false negatives.
---@class starlit.Action.RequiredItemDef
---
---List of item types. Any item of any type listed can satisfy the condition.
---@field types string[] | nil
---
---List of tags. Any item with at least one of the tags can satisfy the condition.
---@field tags string[] | nil
---
---List of predicates the items must pass to be used.
---These are used to implement custom conditions for items.
---@field predicates table<any, starlit.Action.Predicate<InventoryItem>> | nil
---
---Number of items required.
---@field count integer | nil
---
---Whether the item should be moved from any containers into the player's main inventory before performing the action.
---@field mainInventory boolean | nil
---
---How many uses of the item are required. If specified, this overrides <b>count</b> completely.
---@field uses integer | nil
---
---Whether the item will be consumed after the action is complete.
---@field consumed boolean | nil


---Concrete RequiredItem.
---@class starlit.Action.RequiredItem : starlit.Action.RequiredItemDef
---@overload fun(def:starlit.Action.RequiredItemDef):self
---
---List of predicates the items must pass to be used.
---These are used to implement custom conditions for items.
---@field predicates table<any, starlit.Action.Predicate<InventoryItem>>
---
---Number of items required.
---@field count integer
---
---Whether the item should be moved from any containers into the player's main inventory before performing the action.
---@field mainInventory boolean
---
---How many uses of the item are required. If specified, this overrides <b>count</b> completely.
---@field uses integer
---
---Whether the item will be consumed after the action is complete.
---@field consumed boolean
-- common needs for predicates should be made into fields, as they can be optimised this way


---Represents an object requirement for an action.
---@class starlit.Action.RequiredObject
---@overload fun(args:starlit.Action.RequiredObject):self
---
---Conditions an object must meet.
---@field predicates table<any, starlit.Action.Predicate<IsoObject>>


---Action args.
---This is the same as Action, but fields are marked as nullable to avoid the type checker reporting false negatives.
---@class starlit.ActionDef
---
---Translated name of the action. Displayed in context menus and tooltips.
---@field name string | nil
---
---The time it should take to perform the action.
---48 time units are equivalent to 1 real second.
---@field time integer | nil
---
---The animation the character should play during the action.
---@field animation string | nil
---
---Whether to stop the action if the character begins aiming during it.
---@field stopOnAim boolean | nil
---
---Whether to stop the action if the character being walking during it.
---@field stopOnWalk boolean | nil
---
---Whether to stop the action if the character begins running during it.
---@field stopOnRun boolean | nil
---
---List of items required to perform the action.
---The items picked will be stored under <b>state.items</b> with the same key ('name') as in this table.
---If count is 1, the item will be stored directly: otherwise, it will be a list of items.
---@field requiredItems table<any, starlit.Action.RequiredItem> | nil
---
---The name of the item requirement to equip in the primary slot.
---If nil, the character's equipped item will not change.
---If "EMPTY", the character will be forced to unequip any currently equipped item.
---If it is any other string, a requiredItem with the same name will be equipped. (If count > 1, the first item picked will be equipped.)
---If there is no requiredItem going by that name, it will act as a string model name override.
---@field primaryItem string | "EMPTY" | nil
---
---The name of the item requirement to equip in the primary slot.
---If nil, the character's equipped item will not change.
---If "EMPTY", the character will be forced to unequip any currently equipped item.
---If it is any other string, a requiredItem with the same name will be equipped. (If count > 1, the first item picked will be equipped.)
---If there is no requiredItem going by that name, it will act as a string model name override.
---@field secondaryItem string | "EMPTY" | nil
---
---List of objects required to perform the action.
---The objects picked will be stored under <b>state.objects</b> with the same key ('name') as in this table.
---@field requiredObjects table<any, starlit.Action.RequiredObject> | nil
---
---The name of the object in requiredObjects for the character to face while performing the action.
---If nil, the player's facing direction will be unchanged.
---@field faceObject string | nil
---
---The name of the object in requiredObjects for the character to walk to before performing the action.
---If nil, the player will perform the action in their current position.
---@field walkToObject string | nil
---
---Minimum skills required to perform the action.
---@field requiredSkills table<Perk, integer> | nil
---
---List of predicates that must be met to perform the action.
---@field predicates table<any, starlit.Action.Predicate<IsoGameCharacter>> | nil
---
---Animation variables to set at the start of the action. They will be cleared at the end of the action.
---@field animationVariables table<string, boolean | number | string> | nil
---
---Function called upon completion of the action.
---@field complete fun(state:starlit.ActionState) | nil
---
---Function called when the action begins.
---@field start fun(state:starlit.ActionState) | nil
---
---Function called every tick while the action is active.
---@field update fun(state:starlit.ActionState) | nil
---
---Function called when the action is stopped before it is successfully completed.
---@field abort fun(state:starlit.ActionState) | nil


---Concrete Action.
---@class starlit.Action : starlit.ActionDef
---@overload fun(def:starlit.ActionDef):self
---
---Translated name of the action. Displayed in context menus and tooltips.
---@field name string
---
---The time it should take to perform the action.
---48 time units are equivalent to 1 real second.
---@field time integer
---
---Whether to stop the action if the character begins aiming during it.
---@field stopOnAim boolean
---
---Whether to stop the action if the character being walking during it.
---@field stopOnWalk boolean
---
---Whether to stop the action if the character begins running during it.
---@field stopOnRun boolean
---
---List of items required to perform the action.
---The items picked will be stored under <b>state.items</b> with the same key ('name') as in this table.
---If count is 1, the item will be stored directly: otherwise, it will be a list of items.
---@field requiredItems table<any, starlit.Action.RequiredItem>
---
---List of objects required to perform the action.
---The objects picked will be stored under <b>state.objects</b> with the same key ('name') as in this table.
---@field requiredObjects table<any, starlit.Action.RequiredObject>
---
---Minimum skills required to perform the action.
---@field requiredSkills table<Perk, integer>
---
---List of predicates that must be met to perform the action.
---@field predicates table<any, starlit.Action.Predicate<IsoGameCharacter>>
---
---Animation variables to set at the start of the action. They will be cleared at the end of the action.
---@field animationVariables table<string, boolean | number | string>
---
---Function called upon completion of the action.
---@field complete fun(state:starlit.ActionState)
---
---Function called when the action begins.
---@field start fun(state:starlit.ActionState)
---
---Function called every tick while the action is active.
---@field update fun(state:starlit.ActionState)
---
---Function called when the action is stopped before it is successfully completed.
---@field abort fun(state:starlit.ActionState)


local Action = {
    ---@type starlit.Action
    ---@diagnostic disable-next-line: assign-type-mismatch
    Action = SelfMergeTable{
        name = "Unnamed Action",
        time = 192,
        stopOnAim = true,
        stopOnWalk = false,
        stopOnRun = true,
        requiredItems = {},
        requiredObjects = {},
        requiredSkills = {},
        predicates = {},
        animationVariables = {},
        start = pass,
        complete = pass,
        update = pass,
        stop = pass,
        abort = pass
    },
    ---@type starlit.Action.RequiredItem
    ---@diagnostic disable-next-line: assign-type-mismatch
    RequiredItem = SelfMergeTable{
        predicates = {},
        count = 1,
        mainInventory = false,
        uses = 0,
        consumed = false
    },
    ---@type starlit.Action.RequiredObject
    ---@diagnostic disable-next-line: assign-type-mismatch
    RequiredObject = SelfMergeTable{

    },

    ---@type starlit.Action.Predicate
    ---@diagnostic disable-next-line: assign-type-mismatch
    Predicate = SelfMergeTable{
        evaluate = pass,
        description = "DESCRIPTION MISSING"
    },
}


---Returns whether an action is complete.
---An action is considered complete if it has the necessary data to be performed.
---Incomplete actions cannot be performed, but may be used as bases for other actions.
---@param action starlit.Action The action.
---@return boolean complete Whether the action is complete.
---@nodiscard
function Action.isComplete(action)
    if action.name == nil or action.time == nil then
        return false
    end

    for _, item in pairs(action.requiredItems) do
        if not Action.isRequiredItemComplete(item) then
            return false
        end
    end

    for _, object in pairs(action.requiredObjects) do
        if not Action.isRequiredObjectComplete(object) then
            return false
        end
    end

    return true
end


---Returns whether a required item is complete.
---A required item is considered incomplete if it does not contain enough data to pick items.
---Incomplete RequiredItems are very likely to be an error.
---@param requiredItem starlit.Action.RequiredItem The item requirement.
---@return boolean complete Whether the item requirement is complete.
---@nodiscard
function Action.isRequiredItemComplete(requiredItem)
    if (requiredItem.tags ~= nil and #requiredItem.tags > 0)
            or (requiredItem.types ~= nil and #requiredItem.types > 0) then
        return true
    end
    -- return true if any predicates
    for _, _ in pairs(requiredItem.predicates) do
        return true
    end
    return false
end


---Returns whether a required object is complete.
---A required object is considered incomplete if it does not have any predicates.
---Incomplete RequiredObjects are very likely to be an error.
---@param requiredObject starlit.Action.RequiredObject The object requirement.
---@return boolean complete Whether the object requirement is complete.
---@nodiscard
function Action.isRequiredObjectComplete(requiredObject)
    -- returns true if there are any predicates
    for _, _ in pairs(requiredObject.predicates) do
        return true
    end
    return false
end


return Action