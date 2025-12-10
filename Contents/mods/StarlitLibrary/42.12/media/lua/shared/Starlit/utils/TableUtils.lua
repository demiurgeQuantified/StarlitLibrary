local TableUtils = {}

---Takes a list table and returns a lookup table containing all of its elements
---@param t any[]
---@return table<any, true>
TableUtils.toLookup = function(t)
    local t2 = {}

    for i = 1, #t do
        t2[t[i]] = true
    end

    return t2
end

---@param ... any
---@return { any : true }
TableUtils.newLookup = function(...)
    local args = table.newarray(...)
    local result = {}
    for i = 1, #args do
        result[args[i]] = true
    end
    return result
end


---Takes an ArrayList and returns a table containing the same elements 
---@param a ArrayList The ArrayList to copy
---@param t? table The table to fill. If not provided, an array table will be created. Pass an empty table if you can't use an array table.
---@return any[] t Table containing all elements of the ArrayList in the same order
TableUtils.fromArrayList = function(a, t)
    t = t or table.newarray()

    for i = 0, a:size()-1 do
        t[i] = a:get(i)
    end

    return t
end

---Finds a value in a table and returns its position, or nil if it is not found
---@param t any[] The table to search
---@param value any The value to search for
---@return integer? pos The position of the element in the table
TableUtils.find = function(t, value)
    for i = 1, #t do
        if t[i] == value then return i end
    end
end

return TableUtils