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

Examples
--------
A simple task that counts to 5 in the console:
::

    local TaskManager = require("Starlit/Taskmanager")

    -- cache this so we don't have to type out the whole thing every time
    local TaskResult = TaskManager.TaskResult

    -- it is recommended to keep your task chain identifier in a variable to prevent typos
    local TASK_CHAIN = "mymod.mymodule"
    TaskManager.addTaskChain(TASK_CHAIN)


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
    TaskManager.addTask(TASK_CHAIN, task)

An issue with this basic example is that `count` escapes the function, so we can't run more than one of the same task at the same time,
they would share the same counter.
To avoid this, we could create an object to store the state of the function, however this adds a lot of complexity to a very simple program.
An alternative solution would be to make our function async, keeping all of the state within the function.
An async function is essentially a function that can be paused, refered to as 'yielding'.
To call an async function, we have to create a coroutine with that function.
::

    local TaskManager = require("Starlit/Taskmanager")

    local TaskResult = TaskManager.TaskResult

    local TASK_CHAIN = "mymod.mymodule"
    TaskManager.addTaskChain(TASK_CHAIN)

    -- When using EmmyLua, the @async annotation tells the language server that this an async function:
    -- an async function is a function that is meant to be used in a coroutine.
    -- this will generate a warning when you try to call it outside of another async function:
    -- this is important because coroutine.yield will throw an error if you aren't in a coroutine!

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
    TaskManager.addTask(
        TASK_CHAIN,
        -- we cannot pass an async function directly, we must create a new coroutine for that function with coroutine.wrap
        coroutine.wrap(task)
    )
    TaskManager.addTask(
        TASK_CHAIN,
        coroutine.wrap(task)
    )

While the concepts of async functions and coroutines may be more difficult to grasp at first,
you can clearly see how they allow us to write tasks with much more natural and simple code.
