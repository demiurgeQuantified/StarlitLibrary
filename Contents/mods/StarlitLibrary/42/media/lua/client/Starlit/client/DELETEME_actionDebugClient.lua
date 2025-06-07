local ActionUI = require("Starlit/client/action/ActionUI")
local addWindowAction = require("Starlit/DELETEME_actionDebug")


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
ActionUI.addItemAction(addWindowAction, {itemAs = "glass"})
