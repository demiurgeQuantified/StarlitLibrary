-- deprecated Starlit namespace aliases

---@alias Starlit.BaseSquareCursor starlit.BaseSquareCursor
---@alias Starlit.LuaEvent starlit.LuaEvent
---@alias Starlit.TaskManager.Task starlit.TaskManager.Task
---@alias Starlit.TaskManager.RepeatTasks starlit.TaskManager.RepeatTasks
---@alias Starlit.Logger starlit.Logger
---@alias Starlit.FileLogger starlit.FileLogger
---@alias Starlit.TraitInfo starlit.TraitInfo

-- we stopped using callback types because they don't work in emmylua + emmylua can actually type check callbacks
---@alias Starlit.InventoryUI.Callback_OnFillItemTooltip fun(tooltip:ObjectTooltip, layout:Layout, item:InventoryItem)
