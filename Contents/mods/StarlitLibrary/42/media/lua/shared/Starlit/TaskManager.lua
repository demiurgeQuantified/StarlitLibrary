---@namespace starlit


---@class TaskManager.Task
---@field func function
---@field args table


---@class TaskManager.RepeatTasks
---@field offset number
---@field [integer] starlit.TaskManager.Task


---@class taskmanager.TaskChain
---@field name string
---@field tasks fun():TaskManager.TaskResult


local currentTick = 0

local TaskManager = {}


---Result of a task. Determines what the task manager will do with the task after it completes.
---@enum TaskManager.TaskResult
TaskManager.TaskResult = {
    ---Remove the task from the task manager.
    DONE = "done",
    ---Perform the task again next tick.
    CONTINUE = "continue"
}


---@type (fun():TaskManager.TaskResult)[]
local tasks = {}


---@param func fun():TaskManager.TaskResult
function TaskManager.addTask(func)
    tasks[#tasks + 1] = func
end


local function updateTasks()
    for i = #tasks, 1, -1 do
        local success, result = pcall(tasks[i])
        if not success then
            ---@cast result string
            print("Error occured in task: " .. result)
            table.remove(tasks, i)
        elseif result == TaskManager.TaskResult.DONE then
            table.remove(tasks, i)
        else
            assert(
                result == TaskManager.TaskResult.CONTINUE,
                "Task did not return a valid result"
            )
        end
    end
end



---@type table<number, starlit.TaskManager.Task[]>
TaskManager.delayTasks = {}


---@type table<integer, starlit.TaskManager.RepeatTasks>
TaskManager.repeatTasks = {}


---Creates a task to repeat a function every N ticks.
---Note that it is not guaranteed that every invocation is exactly the given number of ticks apart.
---@generic T...
---@param func fun(...: T...) The function to call.
---@param ticks integer How often, in ticks, to call the function.
---@param ... T... Any arguments to the function.
function TaskManager.repeatEveryTicks(func, ticks, ...)
    local repeatFunctions = TaskManager.repeatTasks[ticks]
    if not repeatFunctions then
        repeatFunctions = table.newarray()
        TaskManager.repeatTasks[ticks] = repeatFunctions
    end

    table.insert(repeatFunctions, {func = func, args = table.newarray(...)})
end


---Creates a task to call a function after a delay of N ticks.
---@generic T...
---@param func fun(...: T...) The function to call.
---@param ticks integer The amount of ticks to delay the calling by.
---@param ... T... Any arguments to the function.
function TaskManager.delayTicks(func, ticks, ...)
    local tasks = TaskManager.delayTasks[currentTick + ticks]
    if not tasks then
        tasks = table.newarray()
        TaskManager.delayTasks[currentTick + ticks] = tasks
    end

    table.insert(tasks, {func = func, args = table.newarray(...)})
end


---@param ticks number
function TaskManager.update(ticks)
    currentTick = ticks

    -- run repeat tasks
    for frequency, tasks in pairs(TaskManager.repeatTasks) do
        local amount = #tasks / frequency
        local offset = tasks.offset

        local max = offset + amount
        local overflowAmount = 0.0
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

    updateTasks()
end

Events.OnTick.Add(TaskManager.update)


return TaskManager