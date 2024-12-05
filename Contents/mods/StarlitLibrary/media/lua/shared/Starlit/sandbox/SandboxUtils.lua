local Utils = require "Starlit/utils/Utils"

local SandboxUtils = {}

---Returns the value of a sandbox option by the name given in its script
---@param name string Name of the option
---@return any value Current value of the option
SandboxUtils.getOptionValue = function(name)
    return Utils.findVar(name, SandboxOptions)
end

return SandboxUtils