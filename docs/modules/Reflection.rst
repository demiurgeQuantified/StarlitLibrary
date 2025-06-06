Reflection
==========
::

   local Reflection = require("Starlit/utils/Reflection")

The reflection module provides functions for inspecting and modifying classes and objects, both from Lua and from Java.

.. lua:module:: Reflection

Functions
---------

.. lua:function:: getField(object: any, name: string) -> any

   Returns the value of an object's field by name.
   This can retrieve field values even from objects of unexposed classes.
   It also works for exposed classes however it is less performant than the regular syntax.

   :param any object: The object.
   :param string name: The name of the field.
   :return any value: The value of the field.
   
.. lua:function:: getClassFieldNames(class: string) -> string[] | nil

   Returns a table of the names of every field belonging to that class.
   :param string class: Name of the class.
   :return string[] | nil fields: Field names.

.. lua:function:: hasLocal(callframeOffset: number, name: string) -> hasLocalVariable: boolean

   Returns whether the specified :term:`callframe` has a local variable by that name.

   :param integer callframeOffset: How many callframes downwards to search for the local.
   :param string name: The name of the local variable.
   :return boolean hasLocalVariable: Whether the callframe had a local variable by that name.

.. lua:function:: getLocalValue(callframeOffset: integer, name: string) -> any: value

   Returns the value of a local variable by its name.

   :param integer callframeOffset: How many :term:`callframes <callframe>` downwards to search for the local.
   :param string name: The name of the local variable.
   :return any value: The value of the local variable, or nil if there was no such local. A non-existent local is indistinguishable from a local containing the value nil.

.. lua:function:: getLocalName(callframeOffset: integer, value: any) -> name: string | nil

   Returns the name of a local variable by its value.

   :param integer callframeOffset: How many :term:`callframes <callframe>` downwards to search for the local.
   :param any value: The value of the local to search for.
   :return string | nil name: The name of the first local variable containing the value, or nil if no local variable containing the value could be found.

.. lua:function:: getLocals(callframeOffset: integer) -> locals: table<string, any>

   Returns a table containing all of the local variables in a :term:`callframe`.

   :param integer callframeOffset: How many callframes downwards to get locals from.
   :return table<string, any> locals: The local variables in the callframe.

.. lua:function:: getClassName(object: any) -> string

   Returns the name of the java class or lua type that object is an instance of

   :param any object: The object.
   :return string name: Name of the object's class.

.. lua:function:: registerClassName(metatable: metatable, name: string)

   Registers a class's name for getClassName.

   :param metatable metatable: Metatable of the class.
   :param string name: Name of the class.

Glossary
--------
.. glossary::
   callframe
      Callframes are the context of a function call.
      When a function is called a new callframe is created and placed on top of the stack.
      Remember that all Lua code execution is internally the same as a function call,
      so a file running for the first time is also a callframe, as well as code ran in the console.

      Callframes should not be confused with scopes.
      A callframe will be able to see locals from all scopes visible to the currently executing line of code in that callframe.

      For these functions, offset 0 refers to the current function.
      Offset 1 refers to the function calling the current function.

      .. note::
         In some limited circumstances, locals may be optimised out and will not actually exist at runtime, even if they are defined in the source file.
