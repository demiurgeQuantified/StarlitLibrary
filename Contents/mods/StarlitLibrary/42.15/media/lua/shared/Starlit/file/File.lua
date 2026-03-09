local File = {}

---Returns the full text of the file
---@param path string The path of the file to read
---@param mod? string The id of the mod containing the file. Defaults to searching the Zomboid/Lua/ folder instead
---@return string?
---@nodiscard
File.readFullFile = function(path, mod)
    ---@type BufferedReader
    local reader
    if mod then
        reader = getModFileReader(mod, path, false)
    else
        reader = getFileReader(path, false)
    end
    if not reader then return end

    local totalStr = ""

    local line = reader:readLine()
    if line then
        repeat
            totalStr = totalStr .. line
            line = reader:readLine()
        until line == nil
    end
    reader:close()

    return totalStr
end

return File