local Utils = {}

---Finds a variable by its string name.
---@param name string Name of the variable: "foo.bar" will search for a table named foo, and then look for foo inside of that table
---@param start? table Table to start the search from. Defaults to the global namespace
---@return any result The value of the variable by this name.
---@nodiscard
Utils.findVar = function(name, start)
    local location = luautils.split(name, "%.")
    local result = start or _G
    for j = 1, #location do
        result = result[location[j]]
        if result == nil then return end
    end
    return result
end

---Gets an object from its coordinates and object index.
---@param x integer X coordinate of the object.
---@param y integer Y coordinate of the object.
---@param z integer Z coordinate of the object.
---@param i integer Object index.
---@return IsoObject? object The object at the coordinates with that object index. Nil indicates that the index is out of bounds or the square is not loaded.
---@nodiscard
Utils.getWorldObject = function(x, y, z, i)
    local square = getSquare(x, y, z)
    if not square then return nil end
    local objects = square:getObjects()
    if objects:size() < i then return nil end
    return objects:get(i)
end

return Utils