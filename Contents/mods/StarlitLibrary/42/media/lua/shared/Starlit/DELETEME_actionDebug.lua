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
            mainInventory = true
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
                        -- we have to check this twice because we don't short circuit anymore :()
                        return instanceof(object, "IsoWindow")
                               and object--[[@as IsoWindow]]:isSmashed()
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
    complete = function(state)
        local window = state.objects.window
        ---@cast window IsoWindow
        window:setGlassRemoved(false)
        window:setSmashed(false)
        state.character:getInventory():Remove(state.items.glass)
    end
}

assert(Action.isComplete(addWindowAction))

-- ---@param character IsoGameCharacter
-- ---@param objects IsoObject
-- local function onOptionSelected(character, objects)
--     local failReasons = Actions.tryQueueAction(addWindowAction, character, objects)
--     if failReasons then
--         for i = 1, #failReasons.objects do
--             print("Object requirement not satisfied: " .. failReasons.objects[i])
--         end
--         for i = 1, #failReasons.predicates do
--             print("Predicate requirement not satisfied: " .. failReasons.predicates[i])
--         end
--         for i = 1, #failReasons.items do
--             print("Item requirement not satisfied: " .. failReasons.items[i])
--         end
--     end
-- end


-- Events.OnFillWorldObjectContextMenu.Add(function(playerNum, context, worldObjects, test)
--     local states = {}
--     local failReasons

--     for i = 2, #worldObjects do
--         local object = worldObjects[i]
--         if instanceof(object, "IsoWindow") then
--             local state
--             state, failReasons = ActionState.tryBuildActionState(
--                 addWindowAction,
--                 getSpecificPlayer(playerNum),
--                 worldObjects,
--                 {
--                     objects = {
--                         window = object
--                     }
--                 }
--             )
--             table.insert(states, state)
--         end
--     end

--     if #states == 0 then
--         -- only shows failReasons if at least one window was found and none were valid
--         if failReasons and failReasons.type ~= "forced" then
--             local option = context:addOption("(DEBUG) " .. getText(addWindowAction.name))
--             option.notAvailable = true
--             option.toolTip = ActionUI.createFailTooltip(addWindowAction, failReasons)
--         end
--     else
--         for i = 1, #states do
--             -- IDEA: highlight object when mousing over option
--             context:addOption("(DEBUG) " .. getText(addWindowAction.name), PrepareActionAction.new(states[i]), ISTimedActionQueue.add)
--         end
--     end
-- end)


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
-- ActionUI.addItemAction(addWindowAction, {itemAs = "glass"})
