Bitwise
=======
::

   local Bitwise = require("Starlit/utils/Bitwise")

The Bitwise module defines some `bitwise operation`_ helper functions. These are generally faster than other implementations I've come across.

.. lua:module:: Bitwise

Functions
---------

.. lua:function:: get(int: integer, pos: integer) -> bit: boolean

   Checks the value of a single bit within an integer.

   :param integer int: The integer.
   :param integer pos: Position of the bit, counting from the right, starting with 1.
   :return boolean bit: The value of the bit.

.. lua:function:: set(int: integer, pos: integer, value: boolean) -> int: integer

   Returns the passed integer int modified with the specified bit changed.

   :param integer int: The integer to modify.
   :param integer pos: The position of the bit to modify.
   :param value boolean: The value to set the bit to.
   :return integer int: The modified integer.

.. _bitwise operation: https://en.wikipedia.org/wiki/Bitwise_operation