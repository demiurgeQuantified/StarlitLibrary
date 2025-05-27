local pass = function() end

---@overload fun(def:starlit.ActionDef):starlit.Action
---@nodiscard
local Action = {}

---@param def starlit.Action.RequiredItemDef
---@return starlit.Action.RequiredItem
Action.requiredItemTypes = function(def)
    local o = copyTable(def)

    o._type = "types"
    o.predicates = o.predicates or {}
    o.count = o.count or 1
    o.mustBeSameType = o.mustBeSameType or false

    return o
end

---@param def starlit.Action.RequiredItemDef
---@return starlit.Action.RequiredItem
Action.requiredItemTags = function(def)
    local o = copyTable(def)

    o._type = "tags"
    o.predicates = o.predicates or {}
    o.count = o.count or 1
    o.mustBeSameType = o.mustBeSameType or false

    return o
end

---@param def starlit.Action.RequiredItemDef
---@return starlit.Action.RequiredItem
Action.requiredItemPredicates = function(def)
    local o = copyTable(def)

    o._type = "predicates"
    o.predicates = o.predicates or {}
    o.count = o.count or 1
    o.mustBeSameType = o.mustBeSameType or false

    return o
end

Action.requiredObject = function(def)
    local o = copyTable(def)

    return o
end

---@class starlit.Action.RequiredItemDef
---@field predicates (fun(item:InventoryItem):boolean)[] | nil
---@field count integer | nil
---@field mustBeSameType boolean | nil

---@class starlit.Action.RequiredItem : starlit.Action.RequiredItemDef
---@field _type "types"|"tags"|"predicates"
---@field predicates (fun(item:InventoryItem):boolean)[]
---@field types string[]
---@field tags string[]
---@field count integer
---@field mustBeSameType boolean  # TODO: not implemented

---@class starlit.Action.RequiredObject
---@field sprites string[] | nil
---@field predicates (fun(item:IsoObject):boolean)[] | nil

---@class starlit.ActionDef.requiredItems
---@field prop1 starlit.Action.RequiredItem | nil
---@field prop2 starlit.Action.RequiredItem | nil
---@field [any] starlit.Action.RequiredItem

---@class starlit.ActionDef
---@field name string
---@field time integer
---@field requiredItems starlit.ActionDef.requiredItems | nil
---@field requiredObject starlit.Action.RequiredObject | nil
---@field predicates (fun(character:IsoGameCharacter):boolean)[] | nil
---@field complete fun(state:starlit.ActionState) | nil
---@field start fun(state:starlit.ActionState) | nil
---@field update fun(state:starlit.ActionState) | nil
---@field stop fun(state:starlit.ActionState) | nil

---@class starlit.Action : starlit.ActionDef
---@field requiredItems starlit.ActionDef.requiredItems
---@field predicates (fun(character:IsoGameCharacter):boolean)[]
---@field complete fun(state:starlit.ActionState)
---@field start fun(state:starlit.ActionState)
---@field update fun(state:starlit.ActionState)
---@field stop fun(state:starlit.ActionState)

local meta = {
    ---@param def starlit.ActionDef
    __call = function(self, def)
        local o = copyTable(def)

        o.requiredItems = o.requiredItems or {}
        o.predicates = o.predicates or {}
        o.complete = o.complete or pass
        o.start = o.start or pass
        o.update = o.update or pass
        o.stop = o.stop or pass

        return o
    end
}

---@diagnostic disable-next-line: param-type-mismatch
setmetatable(Action, meta)

return Action