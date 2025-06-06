Version
=======
::

   local Version = require("Starlit/Version")

The Version module contains information and utilities relating to the current version of Starlit. This module should be used to ensure the correct version of Starlit is running if your mod depends on a recent feature.

Functions
---------
.. lua:function:: ensureVersion(major: integer, minor: integer, patch: integer) -> compatible: "toolow" | "toohigh" | "compatible"

   Compares the current version to the requested version, showing a popup to the user if it is not likely to be compatible.
   
   :param integer major: Major version.
   :param integer minor: Minor version.
   :param integer patch: Patch version.
   :return "toolow" \| "toohigh" \| "compatible" compatible: A string indicating if the current version is compatible, or why it isn't.

   .. warning::
      This function currently does not correctly delay the pop-up until the game is ready to display it. To be safe, wait until ``OnGameStart`` to call this function.

.. lua:function:: compareVersion(build: integer, major: integer, minor: integer, patch: integer)

   Compares the version specified to the current version.

   :param integer build: Major game build (41, 42...).
   :param integer major: Major version.
   :param integer minor: Minor version.
   :param integer patch: Patch version.
   :return "toolow" \| "toohigh" \| "compatible" compatible: A string indicating if the current version is compatible, or why it isn't.

Fields
------

.. lua:data:: BUILD integer

   The major game build the current version of Starlit is designed for.

.. lua:data:: MAJOR integer

   The major version of Starlit. Major versions are incremented when non-trivial breaking changes are made to the API.

.. lua:data:: MINOR integer

   The minor version of Starlit. Minor versions are incremented when new features are added, and old features may be deprecated.

.. lua:data:: PATCH integer

   The patch version of Starlit. Patch versions are incremented by bug fixes that don't change (intended) functionality.
