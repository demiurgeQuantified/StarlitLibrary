local pass = function() end

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


---@class starlit.ActionDef
---@field name string
---@field time integer
---@field animation string | nil  -- TODO: not tested
---@field stopOnAim boolean | nil
---@field stopOnWalk boolean | nil
---@field stopOnRun boolean | nil
---@field requiredItems table<any, starlit.Action.RequiredItem> | nil
---@field primaryItem string | nil
---@field secondaryItem string | nil
---@field requiredObjects table<any, starlit.Action.RequiredObject> | nil
---@field faceObject string | nil
---@field walkToObject string | nil
---@field predicates (fun(character:IsoGameCharacter):boolean)[] | nil
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
---@field predicates (fun(character:IsoGameCharacter):boolean)[]
---@field complete fun(state:starlit.ActionState)
---@field start fun(state:starlit.ActionState)
---@field update fun(state:starlit.ActionState)
---@field stop fun(state:starlit.ActionState)


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

---@param def starlit.Action.RequiredObject
---@return starlit.Action.RequiredObject
Action.requiredObject = function(def)
    local o = copyTable(def)

    return o
end

local meta = {
    ---@param def starlit.ActionDef
    ---@return starlit.Action
    __call = function(self, def)
        local o = copyTable(def) --[[@as starlit.Action]]

        o.stopOnAim = o.stopOnAim or false
        o.stopOnWalk = o.stopOnWalk or false
        o.stopOnRun = o.stopOnRun or false

        o.requiredObjects = o.requiredObjects or {}
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