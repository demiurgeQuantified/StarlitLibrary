local JsonLib = require "Starlit/internal/json"
local File = require "Starlit/file/File"

local Json = {}

---Reads a json file and returns a table representing its contents
---@param path string Path of the file to read
---@param mod string|nil The id of the mod containing the file. Defaults to searching the Zomboid/Lua/ folder instead
---@return table?
---@nodiscard
Json.fromFile = function(path, mod)
    local text = File.readFullFile(path, mod)
    if not text then return end

    return JsonLib.decode(text)
end

return Json