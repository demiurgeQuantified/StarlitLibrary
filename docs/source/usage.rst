Usage
======================================

To add the library as a dependency, add the line ``require=\StarlitLibrary`` to your `mod.info`. The game will make sure that Starlit Library will always be enabled if your mod is, and show a warning to users if they are missing the library.

.. note::
   In Build 41, use ``require=StarlitLibrary`` instead.

You will likely want to mark the dependency on your Steam Workshop page too. This will show a pop-up to users installing your mod encouraging them to install the library as well. Unfortunately, the in-game uploader doesn't have a way to do this before uploading.  
To add a Workshop dependency, navigate to your mod's Workshop page, click 'Add/Remove Required Items' in the owner panel, select the Subscribed Items tab and search for Starlit Library.

.. image:: https://github.com/user-attachments/assets/babb88e2-4547-4926-9c91-2bc6237d7ff6
   :width: 500px
.. image:: https://github.com/user-attachments/assets/6dbaa989-a443-4745-a151-d0d0278307f1
   :width: 500px


Using Modules
-------------

Starlit Library's API is developed modularly. This means that to access the API, your Lua file must first ``require`` the module and place it into a local variable. To require a module, you must call the Lua function ``require(path)`` with the path to the file where the module is defined. Every module's page includes sample code for requiring the module.

For example, to use the Version module to check the current version of Starlit, you must require the Version module, place it into a local variable, and then call its functions.
::

   -- require the Version module and put it into a local variable called Version
   local Version = require("Starlit/Version")

   -- print the current Starlit version
   print("Current Starlit Library version is " .. Version.VERSION_STRING)

   -- show a warning to the player if the current version is not at least 1.4.0
   Version.ensureVersion(1, 4, 0)

Using Events
------------

Starlit Library uses a custom implementation of events for performance and API reasons. They use similar logic to Vanilla events, but their syntax is different.
::

   event:addListener(myFunction)
   event:removeListener(myFunction)

Additionally, they are not stored in a global Events table. Events are objects stored within modules, which must as always be required to be accessed.

An example of using the ``onFillItemTooltip`` event from the ``InventoryUI`` module:
::

   -- require the module so we can use it
   local InventoryUI = require("Starlit/client/ui/InventoryUI")

   -- create our event listener function
   local function myListener()
       print("onFillItemTooltip fired!")
   end

   -- register the listener to the event
   InventoryUI.onFillItemTooltip:addListener(myListener)

Debug Menu
----------
The Library has its own debug menu separate from the game's. To open the debug menu, you need to set a keybind for it in your mod options (available only in debug mode). The debug menu contains a list of separate debugging UIs, documented on the pages they are relevant to.

Intellisense
------------

.. note::
   If you don't already have it, you will need [Umbrella](https://github.com/asledgehammer/Umbrella) to define the Vanilla game types. Intellisense for Starlit Library will still work without it, but its usefulness will be limited.

Starlit Library's code is fully type annotated. To get code completion, error checking and other IDE features for Starlit modules, add the ``media/lua/`` folder of your mod installation as a library to your IDE/Lua plugin. The process to do this is IDE specific. Only [VSCode](https://code.visualstudio.com)'s [Lua](https://marketplace.visualstudio.com/items?itemName=sumneko.lua) extension is officially supported, but it should work with any IDE that supports LuaCATS annotations.

VSCode + Lua extension
----------------------
In extension settings, search for the ``Lua - Workspace: Library`` setting and add the path to the ``lua`` folder of your Starlit Library installation. For example, a typical path on Windows would be ``C:\Program Files (x86)\Steam\steamapps\workshop\content\108600\3378285185\mods\StarlitLibrary\42\media\lua``. This may differ if your Steam library is installed to a different place, or you are not using the Steam workshop.

.. image:: https://github.com/user-attachments/assets/cabdb184-f528-45b8-8333-aa78c0b1b321
