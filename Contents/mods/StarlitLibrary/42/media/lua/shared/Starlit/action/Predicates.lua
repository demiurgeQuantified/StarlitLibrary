local Action = require("Starlit/action/Action")


---@using starlit


local Predicates = {}


Predicates.object = {
    ---@type Action.Predicate<IsoObject>
    PredicateSprite = Action.Predicate{
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
}


Predicates.item = {
    ---@type Action.Predicate<InventoryItem>
    NotBroken = Action.Predicate{
        description = getText("IGUI_StarlitLibrary_Predicate_NotBroken"),
        evaluate = function(self, item)
            return not item:isBroken()
        end
    }
}


return Predicates