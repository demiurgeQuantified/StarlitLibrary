---State of a specific action attempt.
---Where an Action defines the kinds of items and objects needed, an ActionState contains the specific items and objects being used in an action.
---@class starlit.ActionState
---
---The Action this ActionState corresponds to.
---@field def starlit.Action
---
---The character performing the action.
---@field character IsoGameCharacter
---
---The items used in the action. Keys correspond to requiredItems.
---Values will be a table if the count of the requiredItem is more than 1. Otherwise they are InventoryItems.
---@field items table<any, InventoryItem | InventoryItem[]>
---
---The objects used in the action. Keys correspond to the action's requiredObjects.
---@field objects table<any, IsoObject>


local ActionTester = require("Starlit/action/ActionTester")


local ActionState = {}


---Checks if the conditions of an action state are still met.
---@param state starlit.ActionState The state to check.
---@return boolean valid Whether the state is still valid.
---@nodiscard
function ActionState.stillValid(state)
    return ActionTester.new(state.character):test(
        state.def,
        {},
        {
            objects = state.objects,
            items = state.items
        })
        ~= nil
end


---Creates an ActionState from a test result.
---The test must be successful to be valid for this function.
---@param testResult starlit.ActionTest.Result Successful test result.
---@return starlit.ActionState state The created state.
---@nodiscard
function ActionState.fromTestResult(testResult)
    assert(testResult.success == true,
           "ActionState: Cannot build ActionState from non-successful TestResult.")

    ---@type starlit.ActionState
    local actionState = {
        def = testResult.action,
        character = testResult.character,
        objects = testResult.objects --[[@as table<any, IsoObject>]],
        items = {}
    }

    for name, result in pairs(testResult.items) do
        ---@cast result InventoryItem[]
        if #result == 1 then
            actionState.items[name] = result[1]
        else
            actionState.items[name] = result
        end
    end

    return actionState
end


return ActionState