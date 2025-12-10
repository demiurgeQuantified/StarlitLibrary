---@type metatable
local selfMergeTableMeta
selfMergeTableMeta = {
    -- when called with a table argument, return both tables merged 
    ---@param t table
    ---@param args table
    __call = function(t, args)
        local o = copyTable(t)
        for k, v in pairs(args) do
            o[k] = v
        end
        return setmetatable(o, selfMergeTableMeta)
    end
}

---A table that, when called, returns another SelfMergeTable with the argument table merged with itself.
---Useful for modelling 'inheritance' in POD structures.
---The table{} call syntax is recommended for calls to a SelfMergeTable.
---@class SelfMergeTable
---@overload fun(t:table):self
local SelfMergeTable = setmetatable({}, selfMergeTableMeta)

return SelfMergeTable