local Iterators = {}

---Iterator for java lists.
---
---Returns an iterator that returns the index of the element and the element - similar to ipairs on tables
---@param o List
---@return fun():number, any
Iterators.apairs = function(o)
    local i = 0
    local n = o:size()
    return function()
        i = i + 1
        if i < n then
            return i, o:get(i)
        ---@diagnostic disable-next-line: missing-return
        end
    end
end

return Iterators