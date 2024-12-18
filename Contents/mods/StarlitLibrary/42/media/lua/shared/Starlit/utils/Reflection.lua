local getNumClassFields = getNumClassFields
local getClassField = getClassField
local getClassFieldVal = getClassFieldVal
local setmetatable = setmetatable
local match = string.match
local tostring = tostring
local pairs = pairs
local __classmetatables = __classmetatables
local type = type
local getmetatable = getmetatable

local Utils = require("Starlit/utils/Utils")

-- umbrella doesn't declare this lol
---@class Field

---@type table<metatable, string>
local classNames = {}
---@type table<string, string[]>
local classFields = {}

---@param field Field
---@return string
---@nodiscard
local getFieldName = function(field)
    return match(tostring(field), "([^%.]+)$")
end

---@param classtable metatable
local function exposeClassFields(classtable)
    local metatable = {}

    ---@param self table
    ---@param key any
    ---@return any
    local getField = function(self, key)
        local field = metatable.fields[key]
        if field then
            return getClassFieldVal(self, field)
        end
    end

    ---@param self table
    ---@param key any
    ---@return any
    metatable.__index = function(self, key)
        ---@type table<string, Field>
        local fields = {}
        local fieldNames = table.newarray()

        for i = 0, getNumClassFields(self)-1 do
            local field = getClassField(self, i)
            local fieldName = getFieldName(field)

            fields[fieldName] = field
            fieldNames[i + 1] = fieldName
        end

        -- if isDebugEnabled() then
        --     for i = 0, getNumClassFunctions(self)-1 do
        --         local method = getClassFunction(self, i)
        --         if match(tostring(method), "^protected ") then
        --             print("STARLIT: Exposing protected method ", method:toGenericString())
        --             method:setAccessible(true)
        --             classtable[method:getName()] = function(self, ...) return method:invoke(self, ...) end
        --         end
        --     end
        -- end

        classFields[classNames[classtable]] = fieldNames
        metatable.fields = fields
        metatable.__index = getField

        return self[key]
    end

    setmetatable(classtable, metatable)
end

---@param metatable metatable Metatable of the class
---@param name string Name of the class
local function registerClassName(metatable, name)
    classNames[metatable] = name
end

---@param t table
local function addClassesRecurse(t)
    for k,v in pairs(t) do
        if type(v) == "table" then
            local class = v.class
            if class then
                local metatable = __classmetatables[class]
                registerClassName(metatable, k)
                exposeClassFields(metatable.__index)
            else
                addClassesRecurse(v)
            end
        end
    end
end
addClassesRecurse(zombie)

local function addClassNamesRecurse(t)
    for k,v in pairs(t) do
        if type(v) == "table" then
            local class = v.class
            if class then
                registerClassName(__classmetatables[class], k)
            else
                addClassNamesRecurse(v)
            end
        end
    end
end
addClassNamesRecurse(java)

-- ---@enum Starlit.PatchType
-- local patchType = {
--     ---Runs before the original function. Arguments are passed in a single table. If the patch returns true, the original function will not be run, and the patch's second return value (or nil) will be returned
--     Prefix = 1,
--     ---Runs after the original function. Arguments are passed as normal. The return value of the original value is passed after all other arguments. If the patch returns true, the return value will be replaced with the patch's second return value (or nil)
--     Postfix = 2,
--     ---Replaces the original function.
--     Override = 3,
--     ---Runs before the original function. Arguments are passed as normal. Return values are ignored.
--     PrefixSimple = 4,
--     ---Runs after the original function. Arguments are passed as normal. Return values are ignored.
--     PostfixSimple = 5,
-- }

-- ---@generic T
-- ---@alias Starlit.PrefixPatch fun(args:any[]):shouldReturn:boolean,returnValue:any
-- ---@alias Starlit.PostfixPatch fun(..., returnValue:T):boolean,T
-- ---@alias Starlit.OverridePatch function
-- ---@alias Starlit.SimplePatch fun(...):void
-- ---@alias Starlit.Patch Starlit.PrefixPatch|Starlit.PostfixPatch|Starlit.OverridePatch|Starlit.SimplePatch

-- ---@alias Starlit.Patcher fun(original:function, patch:Starlit.Patch):function

-- ---@type table<Starlit.PatchType, Starlit.Patcher>
-- local patchers = {}

-- patchers[patchType.Prefix] = function(original, prefix)
--     return function(...)
--         local args = {...}
--         local shouldReturn, returnValue = prefix(args)
--         if shouldReturn then return returnValue end
--         return original(unpack(args))
--     end
-- end

-- patchers[patchType.Postfix] = function(original, postfix)
--     return function(...)
--         local returnValue = original(...)
--         local shouldChange, returnValue = postfix(..., returnValue)
--         if shouldChange then return returnValue end
--     end
-- end

-- patchers[patchType.Override] = function(original, patch)
--     return patch
-- end

-- patchers[patchType.PrefixSimple] = function(original, patch)
--     return function(...)
--         patch()
--         return original(...)
--     end
-- end

-- patchers[patchType.PostfixSimple] = function(original, patch)
--     return function(...)
--         local retVal = original(...)
--         patch()
--         return retVal
--     end
-- end

-----------------------------------------------------------------------------------------------------------------------
-- PUBLIC API
-----------------------------------------------------------------------------------------------------------------------

---Module concerned with meta information about classes and functions. Generally used for debugging
local Reflection = {}

-- Reflection.PatchType = patchType

---Returns the name of the java class or lua type that o is an instance of
---@param o any The object
---@return string name Name of the object's class
Reflection.getClassName = function(o)
    local jClass = classNames[getmetatable(o)]
    if jClass then return jClass end

    local objType = type(o)
    return (objType == "table" and o.Type) or objType
end

---Registers a class's name for getClassName
---@param metatable metatable Metatable of the class
---@param name string Name of the class
function Reflection.registerClassName(metatable, name)
    registerClassName(metatable, name)
end

---Returns a table of the names of every field belonging to that class
---@param class string Name of the class
---@return string[] fields Field names
Reflection.getClassFieldNames = function(class)
    return classFields[class]
end

-- ---Replaces a function with a version patched with patch 
-- ---@param location table The table containing the function
-- ---@param name string The name of the function within the table
-- ---@param patch Starlit.Patch The patch function
-- ---@param patchType Starlit.PatchType The type of patch to apply
-- Reflection.patchFunction = function(location, name, patch, patchType)
--     patchType = patchType or Reflection.PatchType.Prefix
--     location = location or _G

--     local originalFunc = location[name]
--     if not originalFunc then return end

--     local patcher = patchers[patchType]

--     if not patcher then
--         error(string.format("Starlit.Reflection.patchFunction: Invalid PatchType %s", tostring(patchType)), 2)
--         return
--     end

--     local newFunc = patcher(originalFunc, patch)

--     location[name] = newFunc
-- end

-- ---Replaces a function with a version patched with patch, using its full name to locate it
-- ---@param name string The full name of the function 
-- ---@param patch Starlit.Patch The patch function
-- ---@param patchType Starlit.PatchType The type of patch to apply
-- Reflection.patchFunctionName = function(name, patch, patchType)
--     local lastDot = 0
--     while true do
--         local nextDot = string.find(name, "%.", lastDot + 1)
--         if not nextDot then break end
--         lastDot = nextDot
--     end

--     ---@type table
--     local funcLocation

--     if lastDot == 0 then
--         funcLocation = _G
--     else
--         funcLocation = Utils.findVar(string.sub(name, 1, lastDot-1))
--         if not funcLocation then return end
--         name = string.sub(name, lastDot+1)
--     end

--     Reflection.patchFunction(funcLocation, name, patch, patchType)
-- end

-- ---Replaces a java class method with a version patched with patch. Static methods should use the standard function patcher functions
-- ---@param className string Name of the class
-- ---@param methodName string Name of the method
-- ---@param patch Starlit.Patch The patch function
-- ---@param patchType Starlit.PatchType The type of patch to apply
-- Reflection.patchJavaInstanceMethod = function(className, methodName, patch, patchType)
--     Reflection.patchFunction(__classmetatables[_G[className].class].__index, methodName, patch, patchType)
-- end

---@type {string : {string : Field}}
local unexposedObjectFields = {}

---Returns the value of an object's field by name.
---This can retrieve field values even from objects of unexposed classes.
---It also works for exposed classes however it is less performant than the regular syntax.
---@param object any The object
---@param name string The name of the field
---@return any value The value of the field.
Reflection.getUnexposedObjectField = function(object, name)
    local className = string.match(tostring(object), "^(.*)@")
    if not unexposedObjectFields[className] then
        local fieldMap = {}
        for i = 0, getNumClassFields(object)-1 do
            local field = getClassField(object, i)
            fieldMap[getFieldName(field)] = field
        end
        unexposedObjectFields[className] = fieldMap
    end
    return getClassFieldVal(object, unexposedObjectFields[className][name])
end

return Reflection