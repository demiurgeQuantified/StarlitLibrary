Action Framework Guide
======================
.. versionadded:: v1.5.0

Starlit Library provides a framework for mods to add new actions (equivalent to vanilla Timed Actions) without the excessive amount of boilerplate and repeated code.
This page is not documentation of any specific module, but rather an overview of the framework as a whole, as it works quite differently from other parts of the library.

Table inheritance
-----------------
An important concept to understand to use the framework is table inheritance.
In the framework, actions are defined using tables rather than creating subclasses.
However, inheritance is still quite a useful concept for reducing repetition of code.
For this reason, the tables used in the action framework support 'table inheritance'.
To inherit from a table, you can call it like a function, and pass a table of new properties to add.
Lua allows you to omit the brackets usually used for function calls and pass the table literal directly.
::

    local myTable = inheritableTable{
        myProperty = 5,
    }

Assuming ``inheritableTable`` is a table that supports this feature, ``myTable`` will become a copy of that table with ``myProperty`` set to ``5``, overriding any value that was set in the original table.

Defining an action
------------------
Actions are defined using a table.
To create a new action, we `inherit` from the Action template, and set our own properties.
This should be done in a file in the ``shared`` folder.
::

    local Action = require("Starlit/action/Action")

    local MyAction = Action.Action{
        name = "My Action",
        time = 192
    }

For a full list of properties Actions support, see the :ref:`Action` page.

Triggering an action
####################
To trigger an action, you can use this snippet:
::

    local Actions = require("Starlit/action/Actions")
    Actions.tryQueueAction(myAction)

The framework provides a way to automatically add context menu options for your actions with dynamic tooltips, detailed later in this overview.

Making it do something
######################
The above is enough to create a basic action that the player can perform, but most actions will need to actually do something upon completion.
To do this, you can add functions to your action:
::

    local MyAction = Action.Action{
        name = "My Action",
        time = 192,
        -- function called when the action is completed
        complete = function(state)
            state.character:Say("Action complete!")
        end
    }

The ``complete`` function is triggered when the action is successfully finished.
It can be used to implement any functionality needed upon action completion.
The only argument is an :ref:`ActionState`. This object contains all data related to the action being performed.
Actions support more functions than just ``complete``. See :ref:`Action` for more information.

Requirements
############
Most actions require specific items to be used, and specific objects to interact with.
The main motivation in designing the framework was actually to simplify this part of timed action development.

Item requirements
+++++++++++++++++
Item requirements are added to the ``requiredItems`` table.
This table contains :ref:`RequiredItem <RequiredItems>` used for the action.
::

    local MyAction = Action.Action{
        name = "My Action",
        -- list of items required for this action
        requiredItems = {
            Action.RequiredItem{
                -- list of full types of items that are acceptable for this requirement
                types = {"Base.Apple"}
            },
            Action.RequiredItem{
                -- list of item tags that are acceptable for this requirement
                tags = {"Crowbar"}
            }
        }
    }

An item requirement can specify specific item types or tags that are acceptable.
Requirements can optionally be `named` by setting keys for them in the ``requiredItems`` table.
::

    requiredItems = {
        apple = Action.RequiredItem{
            types = {"Base.Apple"}
        },
        crowbar = Action.RequiredItem{
            tags = {"Crowbar"}
        }
    }

When a requirement is named, it can be referenced in several other places.
A requirement with no name is also known as an `anonymous` requirement.

.. warning::

    Because of how Lua parses tables, all named requirements must be defined before any anonymous requirements.

A situation where a named requirement is useful is to make the player equip that item before performing the action.
::

    local MyAction = Action.Action{
        name = "My Action",
        requiredItems = {
            crowbar = Action.RequiredItem{
                tags = {"Crowbar"}
            }
        },
        -- equip the item picked for requirement 'crowbar' before starting the action
        primaryItem = "crowbar"
    }

The name of an item requirement can be given as ``primaryItem`` to make the player equip that item in their primary slot before performing the action.
Named item requirements can also be accessed in action functions:
::

    local MyAction = Action.Action{
        name = "My Action",
        requiredItems = {
            crowbar = Action.RequiredItem{
                tags = {"Crowbar"}
            }
        },
        complete = function(state)
            state.items.crowbar:setCondition(0)
            state.character:Say("My crowbar broke!")
        end
    }

The final concept to understand with requirements are predicates.
Predicates allow you to filter acceptable items by any custom criteria that can be expressed with a Lua function.
::

    local MyAction = Action.Action{
        name = "My Action",
        requiredItems = {
            Action.RequiredItem{
                tags = {"Crowbar"},
                -- list of predicates that must pass for an item to fit this requirement
                predicates = {
                    Action.Predicate{
                        evaluate = function(self, item)
                            return not item:isBroken()
                        end,
                        description = "Is not broken"
                    }
                }
            }
        },
    }

Predicates define an ``evaluate`` function that returns ``true`` if the passed item is valid, and ``false`` if not.
They also define a description for the condition that will be shown in tooltips.

Item requirements support many more properties than described in this brief guide. For more detail, see :ref:`Action.RequiredItem`.

Other requirements
++++++++++++++++++
There are two other kinds of requirements for actions: Object requirements and character predicates.
Object requirements are defined similarly to item requirements, but only take a table of predicates.
Character predicates are added directly to the action, but work the same as other predicates otherwise.
::

    local MyAction = Action.Action{
        name = "My Action",
        requiredObjects = {
            Action.RequiredObject{
                predicates = {
                    -- predicate that checks if the object is a window
                    Action.Predicate{
                        evaluate = function(self, object)
                            return instanceof(object, "IsoWindow")
                        end,
                        description = "Is a window"
                    },
                }
            }
        },
        -- character predicates
        predicates = {
            -- predicate that checks the player does not have a tired moodle
            Action.Predicate{
                evaluate = function(self, character)
                    return character:getMoodles():getMoodleLevel(MoodleType.Tired) == 0
                end,
                description = "Is not tired"
            }
        }
    }

Adding actions to the UI
------------------------
The ActionUI module is responsible for adding actions to the context menus.
Since Actions should be created in the shared folder, but UI only exists for the client, you will need a separate client file to register your action.
::

    local ActionUI = require("Starlit/client/action/ActionUI")
    -- file where MyAction is defined and returned
    local MyAction = require("MyMod/MyAction")


    -- adds an action to the world object context menu (opened when right clicking in the world)
    ActionUI.addObjectAction(MyAction)

    -- adds an action to the inventory context menu (opened when right clicking an item)
    ActionUI.addItemAction(MyAction)

When the respective context menus are opened, an option will be added for the action.
If the action's requirements aren't met, the option will be red and a tooltip will be shown on mouseover showing the action's requirements.
However, generally we will want more control than this.
For example, we don't want to fill the context menu with every single action every time they right click the world.
Generally there is at least one condition that must be met for an action to be considered:
for example, we don't want to show an inventory item option if the item the player clicked on isn't the right kind at all.
To this end, we should also create a TooltipConfiguration.
::

    local config = ActionUI.TooltipConfiguration{
        -- conditions that must be met for an option to be shown
        showFailConditions = {
            -- requirements that must have passed
            required = {
                -- item requirements
                items = {
                    -- the item requirement named 'crowbar' must pass for the option to be shown.
                    crowbar = true
                }
            }
        },
        -- the right clicked item will be forced to be the 'crowbar' item requirement
        -- if this isn't specified then the action is shown as long as the player has any item that meets the criteria
        -- regardless of which one they actually clicked on
        itemAs = "crowbar"
    }

    ActionUI.addItemAction(MyAction, config)

Examples
--------
As reference for a mod using the framework, you can view the source code of Repairable Windows. This mod was the first converted to use the framework, and takes advantage of most of its features. https://github.com/demiurgeQuantified/RepairableWindows
