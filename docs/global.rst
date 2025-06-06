Global Changes
==============

Starlit Library avoids global changes as much as possible to ensure mod compatibility, however in some cases these are necessary. They are documented here:

Java class metatables are modified to allow fields to be accessed with the intuitive ``object.field`` syntax typical of Lua objects and native objects in other languages.::

   local player = getPlayer()
   player:Say("The closest zombie is " .. player.closestZombie .. " away.")

Please be aware that while the syntax resembles a table access, accessing fields invokes a java method and has the associated performance cost. In testing, a field access is around 70% more expensive than a pure getter method, so it should only be used when one doesn't exist.