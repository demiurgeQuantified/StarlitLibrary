TaskManager
===========
The TaskManager module allows for scheduling code.

Many functions in this module take as argument a function to call and a list of arguments to call it with. Remember that if you are using classes, self should be passed as the first argument.

.. lua:automodule:: Starlit.TaskManager
   :members:
   :recursive:

Enum
----
.. lua:autoenum:: starlit.taskmanager.TaskResult
    :members:

Class
-----
.. lua:autoclass:: starlit.taskmanager.TaskChain
    :members:
    :recursive:

Examples
--------
Tasks are functions that, once added, will be called every tick until finished.
An example of a simple task that counts to 5, incrementing by one each tick, printing each number to the console:
::

    local TaskManager = require("Starlit/Taskmanager")

    -- cache this so we don't have to type out the whole thing every time
    local TaskResult = TaskManager.TaskResult

    local taskChain = TaskManager.addTaskChain("mymod.mymodule")


    local count = 0
    local function task()
        count = count + 1
        print(count)
        if count == 5 then
            -- reset the count for next time
            count = 0
            -- return DONE to tell the task manager to stop running this function every tick
            return TaskResult.DONE
        end

        -- continue running the task on the next tick
        return TaskResult.CONTINUE
    end

    -- start running the task next tick
    taskChain:addTask(task)

An issue with this basic example is that ``count`` escapes the function, so we can't run more than one of the same task at the same time,
they would share the same counter.
To avoid this, we could create an object to store the state of the function, however this adds a lot of complexity to a very simple program.

An alternative solution would be to make our function async, keeping all of the state within the function.
An async function is essentially a function that can be paused, refered to as 'yielding'.
To call an async function, we have to create a coroutine with that function.
Async functions are very suitable for tasks.
::

    local TaskManager = require("Starlit/Taskmanager")

    local TaskResult = TaskManager.TaskResult

    local taskChain = TaskManager.addTaskChain("mymod.mymodule")

    -- When using EmmyLua, the @async annotation tells the language server that this is an async function:
    -- an async function is a function that is meant to be used in a coroutine.
    -- This will generate a warning when you try to call it outside of another async function:
    -- This is important because coroutine.yield will throw an error if you aren't in a coroutine!

    ---@async
    local function task()
        for i = 1, 5 do
            print(i)
            -- coroutine.yield pauses the function
            -- CONTINUE tells the task manager we want to resume from here next tick
            coroutine.yield(TaskResult.CONTINUE)
        end

        return TaskResult.DONE
    end

    -- we can now add as many of the task as we want without issue:
    taskChain:addTask(
        -- we cannot pass an async function directly, we must create a new coroutine for that function with coroutine.wrap
        coroutine.wrap(task)
    )
    taskChain:addTask(
        coroutine.wrap(task)
    )

While the concepts of async functions and coroutines may be more difficult to grasp at first,
you can clearly see how they allow us to write tasks with much more natural and simple code.

For a real world example of a task, see WaterGoesBad_, which uses a task to stagger object updates over several ticks (particularly the `update` and `startUpdate` functions).

.. _WaterGoesBad: https://github.com/demiurgeQuantified/WaterGoesBad/blob/develop/Contents/mods/WaterGoesBad/42.13/media/lua/server/WaterGoesBad/WaterObjectManager.lua
