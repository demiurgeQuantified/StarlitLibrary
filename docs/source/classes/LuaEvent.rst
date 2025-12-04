LuaEvent
========
``LuaEvent`` is a Lua implementation of an events system similar to the game's native event system.
For events triggered from Lua, it is slightly faster.
The main benefit to using a ``LuaEvent`` is that the event is an object rather than belonging to a global registry.
They are intended to belong to modules, classes or even objects.
::

   local LuaEvent = require("Starlit/LuaEvent")

.. lua:autoclass:: starlit.LuaEvent
    :members:
    :recursive:
