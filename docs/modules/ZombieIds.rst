ZombieIds
=========
.. versionadded:: v1.5.0

::

   local ZombieIds = require("Starlit/ZombieIds")

The ZombieIds module provides persistent identifiers for zombies. The IDs are guaranteed to be reasonably unique, and stable between library versions. Using identifiers for zombies is often important as their objects are pooled, so object identity comparisons are not reliable; the same IsoZombie object used for one zombie may be reused for another zombie later.

Compared to other libraries that provide similar zombie ids, I have found this to be the fastest implementation by far.

.. lua:module:: ZombieIds

Functions
---------

.. lua:function:: get(zombie: IsoZombie) -> id: integer

   Returns the ID of a zombie.

   :param IsoZombie zombie: The zombie.
   :return integer id: The zombie's id.
