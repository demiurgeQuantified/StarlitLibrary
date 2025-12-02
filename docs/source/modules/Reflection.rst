Reflection
==========

.. lua:automodule:: Starlit.utils.Reflection
   :members:
   :recursive:

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
