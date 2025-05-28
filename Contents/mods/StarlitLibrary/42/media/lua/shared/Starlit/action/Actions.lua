local ActionState = require("Starlit/action/ActionState")
local PrepareActionAction = require("Starlit/internal/PrepareActionAction")


local Actions = {}

---Queues an action from a pre-created state.
---@param state starlit.ActionState The state to queue.
function Actions.queueAction(state)
    ISTimedActionQueue.add(PrepareActionAction.new(state))
end

---Attempts to queue an action.
---If the character is not currently able to perform the action, returns a FailReasons describing why, and does not queue an action.
---@param action starlit.Action The action to queue.
---@param character IsoGameCharacter The character performing the action.
---@param objects IsoObject[] | nil List of objects that may be used in the action.
---@return starlit.ActionState.FailReasons | nil failReasons The reasons why the action cannot be performed. Nil if the action was successfully queued.
function Actions.tryQueueAction(action, character, objects)
    objects = objects or {}
    local state, failReasons = ActionState.tryBuildActionState(
        action,
        character,
        objects
    )
    if not state then
        return failReasons
    end

    Actions.queueAction(state)
end

return Actions