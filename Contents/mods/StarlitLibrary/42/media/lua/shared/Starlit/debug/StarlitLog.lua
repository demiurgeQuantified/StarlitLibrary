local Logger = require("Starlit/debug/Logger")

--- Log used for internal Starlit log messages.
--- Don't use this in your mod - use require("Starlit/debug/Logger").getLogger("MyModName") instead
local StarlitLog = Logger.getLogger("Starlit Library")

return StarlitLog