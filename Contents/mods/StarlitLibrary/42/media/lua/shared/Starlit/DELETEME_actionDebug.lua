local Action = require("Starlit/action/Action")
local ActionUI = require("Starlit/action/ActionUI")


local addWindowAction = Action.Action{
    name = getText("IGUI_RepairableWindows_Action_AddWindow"),
    time = 192,
    stopOnAim = true,
    stopOnRun = true,
    stopOnWalk = true,
    requiredItems = {
        glass = Action.RequiredItem{
            types = {"Base.GlassPanel"},
            mainInventory = true,
            count = 1,
            consumed = true
            -- predicates = {
            --     Action.Predicate{
            --         evaluate = function()
            --             return false
            --         end,
            --         description = "Always false"
            --     }
            -- },
        }
    },
    primaryItem = "EMPTY",
    secondaryItem = "EMPTY",
    requiredObjects = {
        window = Action.RequiredObject{
            predicates = {
                Action.Predicate{
                    evaluate = function(self, object)
                        return instanceof(object, "IsoWindow")
                    end,
                    description = getText("IGUI_RepairableWindows_Predicate_IsWindow")
                },
                Action.Predicate{
                    evaluate = function(self, object)
                        -- we have to check instanceof twice because we don't short circuit anymore :(
                        return instanceof(object, "IsoWindow") ---@cast object IsoWindow
                               and object:isSmashed()
                    end,
                    description = getText("IGUI_RepairableWindows_Predicate_IsSmashed")
                }
            }
        }
    },
    faceObject = "window",
    walkToObject = "window",
    -- predicates = {
    --     Action.Predicate{
    --         evaluate = function()
    --             return false
    --         end,
    --         description = "Always false"
    --     }
    -- },
    requiredSkills = {
        [Perks.Woodwork] = 2
    },
    complete = function(state)
        local window = state.objects.window --[[@as IsoWindow]]
        window:setGlassRemoved(false)
        window:setSmashed(false)
    end
}

assert(Action.isComplete(addWindowAction))


-- for i = 1, 500 do
    ActionUI.addObjectAction(
        addWindowAction,
        ActionUI.TooltipConfiguration{
            highlight = {
                object = "window"
            },
            objectAs = "window",
            showFailConditions = {
                noSuccesses = true,
                onlyOne = false,
                required = {
                    objects = {
                        ["window"] = true
                    }
                }
            }
        }
    )
-- end
ActionUI.addItemAction(addWindowAction, {itemAs = "glass"})
