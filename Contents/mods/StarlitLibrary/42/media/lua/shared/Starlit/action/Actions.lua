local ActionState = require("Starlit/action/ActionState")
local ActionTest = require("Starlit/action/ActionTest")
local PrepareActionAction = require("Starlit/internal/PrepareActionAction")


local Actions = {}

---Queues an action from an existing state.
---@param state starlit.ActionState The state to queue.
function Actions.queueAction(state)
    ISTimedActionQueue.add(PrepareActionAction.new(state))
end

---Attempts to queue an action.
---If the character is not currently able to perform the action, does not queue an action.
---@param action starlit.Action The action to queue.
---@param character IsoGameCharacter The character performing the action.
---@param objects IsoObject[] | nil List of objects that may be used in the action.
---@return starlit.ActionTest.Result testResult The reasons why the action cannot be performed.
---@nodiscard
function Actions.tryQueueAction(action, character, objects)
    objects = objects or {}
    local result = ActionTest.test(
        action,
        character,
        objects
    )

    if not result.success then
        return result
    end

    Actions.queueAction(ActionState.fromTestResult(result))

    return result
end

return Actions