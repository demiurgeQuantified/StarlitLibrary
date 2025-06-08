ZombieData
==========
.. versionadded:: v1.5.0

::

   local ZombieData = require("Starlit/ZombieData")

The ZombieData module provides persistent storage associated with a specific zombie, similar to mod data. Zombie mod data, unlike mod data belonging to other objects, is not suitable for this usage as it is not persistent. Like mod data, zombie data cannot store objects or functions, only Plain Old Data.

.. lua:module:: ZombieData

Functions
---------

.. lua:function:: get(zombie: IsoZombie) -> zombieData: table

   Returns the zombie data for a zombie.

   :param IsoZombie zombie: The zombie.
   :return table zombieData: The zombie data.
