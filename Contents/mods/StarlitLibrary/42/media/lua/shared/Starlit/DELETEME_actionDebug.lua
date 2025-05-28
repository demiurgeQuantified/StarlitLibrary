local Action = require("Starlit/action/Action")
local Actions = require("Starlit/action/Actions")

---@type umbrella.ItemContainer_Predicate
local predicateNotBroken = function(item)
    return not item:isBroken()
end


local myAction = Action.Action{
    name = "MyAction",
    time = 500,
    requiredItems = {
        prop1 = Action.RequiredItem{
            types = {"Base.Shovel", "Base.PickAxe"},
            predicates = {predicateNotBroken},
            count = 5
        },
        prop2 = Action.RequiredItem{
            tags = {"TakeDirt"}
        },
        Action.RequiredItem{
            predicates = {predicateNotBroken}
        }
    },
    -- requiredObject = Action.requiredObject{
    --     sprites = {"sprite_name_0_1"},
    --     predicates = {predicateNotBroken}
    -- },
    predicates = {},
    complete = function(state)
        print("complete")
    end,
    start = function(state)
        print("start")
    end,
    update = function(state)
        print("update")
    end,
    stop = function(state)
        print("stop")
    end
}


local addWindowAction = Action.Action{
    name = "AddWindow",
    time = 192,
    stopOnAim = true,
    stopOnRun = true,
    stopOnWalk = true,
    requiredItems = {
        glass = Action.RequiredItem{
            types = {"Base.GlassPanel"},
            mainInventory = true
        }
    },
    primaryItem = "EMPTY",
    secondaryItem = "EMPTY",
    requiredObjects = {
        window = Action.RequiredObject{
            predicates = {
                function (object)
                    return instanceof(object, "IsoWindow") --[[@cast object IsoWindow]]
                        and object:isExistInTheWorld()
                        and object:isSmashed()
                end
            }
        }
    },
    faceObject = "window",
    walkToObject = "window",
    complete = function(state)
        local window = state.objects.window
        ---@cast window IsoWindow
        window:setGlassRemoved(false)
        window:setSmashed(false)
        state.character:getInventory():Remove(state.items.glass)
    end
}


Events.OnFillWorldObjectContextMenu.Add(function(playerNum, context, worldObjects, test)
    for i = 1, #worldObjects do
        local object = worldObjects[i]
        if instanceof(object, "IsoWindow") then
            context:addOption("(DEBUG) Attempt replace window", addWindowAction, Actions.tryQueueAction, getSpecificPlayer(playerNum), {object})
        end
    end
end)


DEBUG_TEST_ACTION = function()
    Actions.tryQueueAction(myAction, getPlayer())
end
