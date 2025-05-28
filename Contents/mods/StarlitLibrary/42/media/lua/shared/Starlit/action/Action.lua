local pass = function() end


---@type metatable
local selfMergeTableMeta
selfMergeTableMeta = {
    -- when called with a table argument, return both tables merged 
    ---@param t table
    ---@param args table
    __call = function(t, args)
        local o = copyTable(t)
        for k, v in pairs(args) do
            o[k] = v
        end
        return setmetatable(o, selfMergeTableMeta)
    end
}

---@overload fun(table, table): table
local selfMergeTable = setmetatable({}, selfMergeTableMeta)


---@class starlit.Action.Predicate<T>
---@field evaluate fun(starlit.Action.Predicate, T):boolean
---@field description string
---@overload fun(other:starlit.Action.Predicate):starlit.Action.Predicate


---@class starlit.Action.RequiredItemDef
---@field types string[] | nil
---@field tags string[] | nil
---@field predicates starlit.Action.Predicate<InventoryItem>[] | nil
---@field count integer | nil
---@field mainInventory boolean | nil
---@field mustBeSameType boolean | nil


---@class starlit.Action.RequiredItem : starlit.Action.RequiredItemDef
---@field predicates starlit.Action.Predicate<InventoryItem>[]
---@field count integer
---@field mainInventory boolean
---@field mustBeSameType boolean  # TODO: not implemented
-- common needs for predicates should be made into fields, as they can be optimised into a single predicate


---@class starlit.Action.RequiredObject
---@field predicates starlit.Action.Predicate<IsoObject>[] | nil


---@class starlit.ActionDef
---@field name string
---@field time integer
---@field animation string | nil  # TODO: not tested
---@field stopOnAim boolean | nil
---@field stopOnWalk boolean | nil
---@field stopOnRun boolean | nil
---@field requiredItems table<any, starlit.Action.RequiredItem> | nil
---@field primaryItem string | nil
---@field secondaryItem string | nil
---@field requiredObjects table<any, starlit.Action.RequiredObject> | nil
---@field faceObject string | nil
---@field walkToObject string | nil
---@field predicates starlit.Action.Predicate<IsoGameCharacter>[] | nil
---@field complete fun(state:starlit.ActionState) | nil
---@field start fun(state:starlit.ActionState) | nil
---@field update fun(state:starlit.ActionState) | nil
---@field stop fun(state:starlit.ActionState) | nil


---@class starlit.Action : starlit.ActionDef
---@field stopOnAim boolean
---@field stopOnWalk boolean
---@field stopOnRun boolean
---@field requiredItems table<any, starlit.Action.RequiredItem>
---@field requiredObjects table<any, starlit.Action.RequiredObject>
---@field predicates starlit.Action.Predicate<IsoGameCharacter>[]
---@field complete fun(state:starlit.ActionState)
---@field start fun(state:starlit.ActionState)
---@field update fun(state:starlit.ActionState)
---@field stop fun(state:starlit.ActionState)

local Action = {
    ---@overload fun(def:starlit.ActionDef):starlit.Action
    ---@nodiscard
    Action = selfMergeTable{
        stopOnAim = false,
        stopOnWalk = false,
        stopOnRun = false,
        requiredItems = {},
        requiredObjects = {},
        predicates = {},
        start = pass,
        complete = pass,
        update = pass,
        stop = pass,
    },
    ---@overload fun(def:starlit.Action.RequiredItemDef):starlit.Action.RequiredItem
    ---@nodiscard
    RequiredItem = selfMergeTable{
        predicates = {},
        count = 1,
        mainInventory = false,
        mustBeSameType = false,
    },
    ---@overload fun(def:starlit.Action.RequiredObject):starlit.Action.RequiredObject
    ---@nodiscard
    RequiredObject = selfMergeTable{

    },

    ---@type starlit.Action.Predicate
    Predicate = selfMergeTable{
        evaluate = pass,
        description = "DESCRIPTION MISSING"
    },
}

---@type starlit.Action.Predicate<IsoObject>
Action.PredicateSprite = Action.Predicate{
    ---@type table<string, boolean>
    sprites = {},
    evaluate = function(self, object)
        local sprite = object:getSprite()
        if not sprite then
            return false
        end
        return self.sprites[sprite:getName()]
    end,
    description = "DESCRIPTION MISSING"
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
    return (requiredItem.tags ~= nil and #requiredItem.tags > 0)
        or (requiredItem.types ~= nil and #requiredItem.types > 0)
        or (#requiredItem.predicates > 0)
end

---Returns whether a required object is complete.
---A required object is considered incomplete if it does not have any predicates.
---Incomplete RequiredObjects are very likely to be an error.
---@param requiredObject starlit.Action.RequiredObject The object requirement.
---@return boolean complete Whether the object requirement is complete.
---@nodiscard
function Action.isRequiredObjectComplete(requiredObject)
    return #requiredObject.predicates > 0
end


return Action