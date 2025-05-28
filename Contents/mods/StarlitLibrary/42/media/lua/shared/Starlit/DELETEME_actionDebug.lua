local Action = require("Starlit/action/Action")
local Actions = require("Starlit/action/Actions")
local ActionState = require("Starlit/action/ActionState")
local PrepareActionAction = require("Starlit/internal/PrepareActionAction")
local ActionUI = require("Starlit/action/ActionUI")


local addWindowAction = Action.Action{
    name = "IGUI_RepairableWindows_Action_AddWindow",
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
                        return instanceof(object, "IsoWindow") --[[@cast object IsoWindow]]
                            and object:isExistInTheWorld()
                            and object:isSmashed()
                    end,
                    description = "IGUI_RepairableWindows_Predicate_IsSmashedWindow"
                }
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

assert(Action.isComplete(addWindowAction))

---@param character IsoGameCharacter
---@param objects IsoObject
local function onOptionSelected(character, objects)
    local failReasons = Actions.tryQueueAction(addWindowAction, character, objects)
    if failReasons then
        for i = 1, #failReasons.objects do
            print("Object requirement not satisfied: " .. failReasons.objects[i])
        end
        for i = 1, #failReasons.predicates do
            print("Predicate requirement not satisfied: " .. failReasons.predicates[i])
        end
        for i = 1, #failReasons.items do
            print("Item requirement not satisfied: " .. failReasons.items[i])
        end
    end
end

Events.OnFillWorldObjectContextMenu.Add(function(playerNum, context, worldObjects, test)
    local state, failReasons = ActionState.tryBuildActionState(
        addWindowAction,
        getSpecificPlayer(playerNum),
        worldObjects
    )
    for i = 1, #worldObjects do
        local object = worldObjects[i]
        if instanceof(object, "IsoWindow") then
            if state then
                context:addOption("(DEBUG) Replace window", PrepareActionAction.new(state), ISTimedActionQueue.add)
            elseif failReasons then
                local option = context:addOption("(DEBUG) Replace window")
                option.notAvailable = true
                option.toolTip = ActionUI.createFailTooltip(addWindowAction, failReasons)
            end
        end
    end
end)
