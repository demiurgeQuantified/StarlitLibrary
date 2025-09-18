---@class starlit.TaskManager.Task
---@field func function
---@field args table

---@class starlit.TaskManager.RepeatTasks
---@field offset number
---@field [integer] starlit.TaskManager.Task

local currentTick = 0

local TaskManager = {}


---@type table<number, starlit.TaskManager.Task[]>
TaskManager.delayTasks = {}


---@type table<integer, starlit.TaskManager.RepeatTasks>
TaskManager.repeatTasks = {}


---Creates a task to repeat a function every N ticks.
---Note that it is not guaranteed that every invocation is exactly the given number of ticks apart.
---@param func function The function to call.
---@param ticks integer How often, in ticks, to call the function.
---@param ... any Any arguments to the function.
TaskManager.repeatEveryTicks = function(func, ticks, ...)
    local repeatFunctions = TaskManager.repeatTasks[ticks]
    if not repeatFunctions then
        repeatFunctions = table.newarray()
        TaskManager.repeatTasks[ticks] = repeatFunctions
    end

    table.insert(repeatFunctions, {func = func, args = table.newarray(...)})
end


---Creates a task to call a function after a delay of N ticks.
---@param func function The function to call.
---@param ticks integer The amount of ticks to delay the calling by.
---@param ... any Any arguments to the function.
TaskManager.delayTicks = function(func, ticks, ...)
    local tasks = TaskManager.delayTasks[currentTick + ticks]
    if not tasks then
        tasks = table.newarray()
        TaskManager.delayTasks[currentTick + ticks] = tasks
    end

    table.insert(tasks, {func = func, args = table.newarray(...)})
end


---@type Callback_OnTick
TaskManager.update = function(ticks)
    currentTick = ticks

    -- run repeat tasks
    for frequency, tasks in pairs(TaskManager.repeatTasks) do
        local amount = #tasks / frequency
        local offset = tasks.offset

        local max = offset + amount
        local overflowAmount = 0
        if max > #tasks then
            overflowAmount = max - #tasks
            for i = 1, math.floor(overflowAmount) do
                local task = tasks[i]
                task.func(unpack(task.args))
            end
        end


        for i = math.floor(offset) + 1, math.floor(max - overflowAmount) do
            local task = tasks[i]
            task.func(unpack(task.args))
        end

        tasks.offset = overflowAmount == 0 and offset + amount or overflowAmount
        if tasks.offset >= #tasks then
            tasks.offset = 0
        end
    end

    -- run delayed tasks
    local delayedTasks = TaskManager.delayTasks[currentTick]
    if delayedTasks then
        for i = 1, #delayedTasks do
            local task = delayedTasks[i]
            task.func(unpack(task.args))
        end
        TaskManager.delayTasks[currentTick] = nil
    end
end

Events.OnTick.Add(TaskManager.update)


return TaskManager