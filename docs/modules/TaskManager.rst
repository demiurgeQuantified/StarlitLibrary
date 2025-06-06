TaskManager
===========
::

   local TaskManager = require("Starlit/TaskManager")

The TaskManager module allows for scheduling code.

Many functions in this module take as argument a function to call and a list of arguments to call it with. Remember that if you are using classes, self should be passed as the first argument.

Functions
---------

.. lua:function:: repeatEveryTicks(func: function, ticks: integer, ...: any)

   Creates a task to repeat a function every N ticks.
   Note that it is not guaranteed that every invocation is exactly the given number of ticks apart.

   :param function func: The function to call.
   :param integer ticks: How often, in ticks, to call the function.
   :param any ...: Any arguments to the function.

.. lua:function:: delayTicks(func: function, ticks: integer, ...: any)

   Creates a task to call a function after a delay of N ticks.

   :param function func: The function to call.
   :param integer ticks: The amount of ticks to delay the calling by.
   :param any ...: Any arguments to the function.
