Time
====
.. versionadded:: v1.5.0

::

   local Time = require("Starlit/utils/Time")

The Time module contains utilities for working with real and game time values. For scheduling functions, see :ref:`TaskManager <TaskManager>`.

.. lua:module:: Time

Enums
-----

.. lua:enum:: starlit.Time.UnitName = "seconds" | "minutes" | "hours" | "days" | "weeks" | "months" | "years"

   Time units recognised by the module.

Functions
---------

.. lua:function:: durationToRealTime(time: number) -> number

   Converts a game time duration to real time.

   :param number time: Game time duration. The unit doesn't matter, but other functions in this module expect hours.
   :return number: Real time equivalent of <i>hours</i> in the same unit as given.

.. lua:function:: durationToGameTime(time: number) -> number

   Converts a real time duration to game time.

   :param number time: Real time duration. The unit doesn't matter, but other functions in this module expect hours.
   :return number: Game time equivalent of <i>hours</i> in the same unit as given.


.. lua:function:: formatDuration(time: number, minUnit: starlit.Time.UnitName | nil, maxUnit: starlit.Time.UnitName | nil) -> string

   Formats a string describing a time duration. The result is suitable for display to the user.

   :param number time: Duration in hours.
   :param starlit.Time.UnitName | nil minUnit: Smallest unit to render the time in. If nil, a reasonable value will be calculated.
   :param starlit.Time.UnitName | nil maxUnit: Largest unit to render the time in. If nil, a reasonable value will be calculated.
   :return string: String description of the duration <i>time</i>.
