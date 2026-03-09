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
---@field package func fun(...:T...):taskmanager.TaskResult
---@field package args [T...]
---@field package removed boolean Whether the task should be considered removed.


local currentTick = 0

---@type taskmanager.TaskChain[]
local chains = table.newarray()


---@type taskmanager.TaskChain?
local executingChain = nil


---@class taskmanager.TaskChain
---@field package name string
---@field package tasks taskmanager.Task[]
local __TaskChain = {}
__TaskChain.__index = __TaskChain


---Adds a task to the chain.
---The task's function will be called every tick until it returns :lua:data:`starlit.taskmanager.TaskResult.DONE`.
---@generic T...
---@param func fun(...:T...):taskmanager.TaskResult Function to call when running the task.
---@param ... T... Arguments to call func with.
---@return taskmanager.Task task Handle to the task. This can be used to query the task later.
function __TaskChain:addTask(func, ...)
    ---@type taskmanager.Task
    local task = {
        func = func,
        args = {...},
        removed = false
    }

    self.tasks[#self.tasks + 1] = task
    return task
end


---Removes a task.
---
---A task from another chain has an undefined result: only pass tasks created by this chain.
---@param task taskmanager.Task Task to remove.
function __TaskChain:removeTask(task)
    task.removed = true

    if self == executingChain then
        return
    end

    for i = 1, #self.tasks do
        if self.tasks[i] == task then
            table.remove(self.tasks, i)
            break
        end
    end
end


---Returns whether this chain has a task.
---
---A task from another chain has an undefined result: only pass tasks created by this chain.
---@param task taskmanager.Task? Task to check. Nil will always result in ``false``.
---@return boolean hasTask Whether the task is still running. If not, then the task has ended or been removed.
---@return_cast task -nil
---@nodiscard
function __TaskChain:hasTask(task)
    return task and not task.removed or false
end


local TaskManager = {}


---.. versionadded:: v1.5.0
---
---Result values for a task. Determines what the task manager will do with the task after it completes.
---If a task doesn't return one of these values an error will be raised!
---@enum taskmanager.TaskResult
TaskManager.TaskResult = {
    ---Remove the task from the task manager.
    DONE = "done",
    ---Perform the task again next tick.
    CONTINUE = "continue"
}


---.. versionadded:: v1.5.0
---
---Creates a task chain.
---
---It is recommended to create a task chain for each file/module that needs one rather than sharing one across your mod.
---Unrelated modules rarely have a good reason to interact with each other's tasks directly,
---and chains are very lightweight.
---
---Task chains should not be disposed of:
---the task manager holds a reference to all created chains that will not be removed until Lua reloads,
---therefore doing so results in a memory leak.
---@param name string Name of the task chain. The format 'modname.modulename' is recommended to avoid overlap.
---@return taskmanager.TaskChain chain
---@nodiscard
function TaskManager.addTaskChain(name)
    local chain = setmetatable({
        name = name,
        tasks = table.newarray()
    }, __TaskChain)

    chains[#chains + 1] = chain    

    return chain
end


local function doTasks()
    for i = 1, #chains do
        local chain = chains[i]
        executingChain = chain

        for j = #chain.tasks, 1, -1 do
            local task = chain.tasks[j]
            local success, result = pcall(
                task.func,
                unpack(task.args)
            )

            if not success then
                ---@cast result string
                log:warn(
                    "error occured in chain '%s': %s",
                    chain.name,
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
                    "chain '%s' task did not return a valid result",
                    chain.name
                )
                task.removed = true
            end
        end

        -- remove tasks that were set as removed during execution
        for j = #chain.tasks, 1, -1 do
            local task = chain.tasks[j]
            if task.removed then
                table.remove(chain.tasks, j)
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

    doTasks()
end

Events.OnTick.Add(TaskManager.update)


return TaskManager