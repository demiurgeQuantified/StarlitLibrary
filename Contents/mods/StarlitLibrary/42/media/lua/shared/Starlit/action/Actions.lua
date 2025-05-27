local ActionState = require("Starlit/action/ActionState")
local PrepareActionAction = require("Starlit/internal/PrepareActionAction")

local Actions = {}

---@param action starlit.Action
---@param character IsoGameCharacter
---@param objects IsoObject[] | nil
function Actions.tryQueueAction(action, character, objects)
    objects = objects or {}
    local state = ActionState.tryBuildActionState(
        action,
        character,
        objects
    )
    if not state then
        return
    end

    ISTimedActionQueue.add(PrepareActionAction.new(state))
end

return Actions