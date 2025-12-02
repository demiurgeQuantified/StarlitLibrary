---@namespace starlit


-- TODO: api for 'sub loggers' for categories like this
local log = require("Starlit/debug/Logger").getLogger("StarlitLibrary] [TaskManager")


---@class TaskManager.Task
---@field func function
---@field args table


---@class TaskManager.RepeatTasks
---@field offset number
---@field [integer] starlit.TaskManager.Task


---@class taskmanager.Task<T...>
---@field func fun(...:T...):taskmanager.TaskResult
---@field args [T...]
---@field name string
---@field removed boolean Whether the task should be considered removed. Set when it is not safe to remove the task immediately.


---@class taskmanager.TaskChain
---@field name string
---@field tasks taskmanager.Task[]
---@field taskMap table<string, taskmanager.Task>


local currentTick = 0

---@type table<string, taskmanager.TaskChain>
local chains = {}


---@type string?
local executingChain = nil


local TaskManager = {}


---.. versionadded:: v1.5.0
---
---Result values for a task. Determines what the task manager will do with the task after it completes.
---A task that does not return one of these values will error!
---@enum taskmanager.TaskResult
TaskManager.TaskResult = {
    ---Remove the task from the task manager.
    DONE = "done",
    ---Perform the task again next tick.
    CONTINUE = "continue"
}


---.. versionadded:: v1.5.0
---
---Creates a task chain. It is necessary to call this function to create a task chain before adding tasks to it.
---There cannot be more than one task chain with the same name. An error will be raised if a duplicate is created.
---@param name string Name of the task chain. The format 'modname.modulename' is recommended to avoid overlap.
function TaskManager.addTaskChain(name)
    assert(
        chains[name] == nil,
        "task chain " .. name .. " already exists"
    )

    chains[name] = {
        name = name,
        tasks = table.newarray(),
        taskMap = {}
    }
end

---.. versionadded:: v1.5.0
---
---Adds a task.
---The task's function will be called every tick until it returns :lua:data:`starlit.taskmanager.TaskResult.DONE`.
---@generic T...
---@param chain string Name of the task chain to add the task to. If no chain by that name exists an error will be raised.
---@param func fun(...:T...):taskmanager.TaskResult Function to call when running the task.
---@param ... T... Arguments to call func with.
---@return string name Name of the task. This can be used to query the task later.
function TaskManager.addTask(chain, func, ...)
    local chainObj = chains[chain]
    assert(
        chainObj ~= nil,
        "task chain " .. chain .. " does not exist"
    )

    ---@type taskmanager.Task
    local task = {
        func = func,
        args = {...},
        name = getRandomUUID(),
        removed = false
    }

    chainObj.tasks[#chainObj.tasks + 1] = task
    chainObj.taskMap[task.name] = task
    return task.name
end


---.. versionadded:: v1.5.0
---
---Removes a task by name.
---@param chain string Name of the task chain to remove the task from. If no chain by that name exists an error will be raised.
---@param name string Name of the task to remove. If no task by that name exists an error will be raised.
function TaskManager.removeTask(chain, name)
    local chainObj = chains[chain]
    assert(
        chainObj ~= nil,
        "task chain " .. chain .. " does not exist"
    )

    local task = chainObj.taskMap[name]
    assert(
        task ~= nil,
        "task chain has no such task " .. name
    )

    if chain == executingChain then
        task.removed = true
        return
    end

    for i = 1, #chainObj.tasks do
        if chainObj.tasks[i] == task then
            table.remove(chainObj.tasks, i)
            break
        end
    end
end


---.. versionadded:: v1.5.0
---
---Returns whether the chain has a task with that name. If not then the task is no longer running.
---@param chain string
---@param name string
---@return boolean
---@nodiscard
function TaskManager.hasTask(chain, name)
    local chainObj = chains[chain]
    assert(
        chainObj ~= nil,
        "task chain " .. chain .. " does not exist"
    )

    local task = chainObj.taskMap[name]

    return task ~= nil and not task.removed
end


local function updateTasks()
    for _, chain in pairs(chains) do
        executingChain = chain.name

        for i = #chain.tasks, 1, -1 do
            local task = chain.tasks[i]
            local success, result = pcall(
                task.func,
                unpack(task.args)
            )

            if not success then
                ---@cast result string
                log:warn(
                    "error occured in chain %s task %s: %s",
                    chain.name,
                    task.name,
                    result
                )
                task.removed = true
            elseif result == TaskManager.TaskResult.DONE then
                task.removed = true
            elseif result == TaskManager.TaskResult.CONTINUE then
                -- do nothing lol
            else
                pcall(
                    log.error,
                    log,
                    "chain %s task %s did not return a valid result",
                    chain.name,
                    task.name
                )
                task.removed = true
            end
        end

        -- remove tasks that were queued for removal during execution
        for i = #chain.tasks, 1, -1 do
            local task = chain.tasks[i]
            if task.removed then
                table.remove(chain.tasks, i)
            end
        end
    end

    executingChain = nil
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
    currentTick = math.floor(ticks)

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