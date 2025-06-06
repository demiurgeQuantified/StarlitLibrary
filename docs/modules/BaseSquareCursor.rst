BaseSquareCursor
================

::

   local BaseSquareCursor = require("Starlit/client/BaseSquareCursor")

BaseSquareCursor is a base class for square cursors, such as the Vanilla building cursor. It exists primarily because Vanilla does not have an easy to use base cursor class: every cursor is built on top of the building cursor, manually disabling all of its functionality. This is hard to work with and requires a large amount of boilerplate code.

To activate a cursor, create an instance of the class and set it as the player's drag:
::

   local cursor = MyCursor.new(player)
   getCell():setDrag(player:getPlayerNum(), cursor)

.. warning::
   The following names are reserved for internal Starlit usage in this class:  
   ``_isStarlitCursor``, ``_selectedThisTick``, ``_isValidCache``, ``_isValidCacheSquare``, ``rotateKey``  
   If you create new members with these names, you may run into issues.

.. lua:autoobject:: starlit.BaseSquareCursor
   :members:
