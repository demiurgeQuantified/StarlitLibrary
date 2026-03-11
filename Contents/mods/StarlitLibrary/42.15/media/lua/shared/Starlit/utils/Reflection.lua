-----------------------------------------------------------------------------------------------------------------------
-- PUBLIC API
-----------------------------------------------------------------------------------------------------------------------

---Module concerned with meta information about classes and functions. Generally used for debugging
local Reflection = {}

-- Reflection.PatchType = patchType

---Returns the name of the java class or lua type that o is an instance of
---@param o any The object
---@return string name Name of the object's class
---@nodiscard
---@[deprecated("Field reflection related functions no longer work: TIS removed reflection API")]
---@doc deprecated
Reflection.getClassName = function(o)
    error("TIS removed reflection API, this module no longer works.")
end

---Registers a class's name for getClassName
---@param metatable metatable Metatable of the class
---@param name string Name of the class
---@[deprecated("Field reflection related functions no longer work: TIS removed reflection API")]
function Reflection.registerClassName(metatable, name)
    error("TIS removed reflection API, this module no longer works.")
end

---Returns a table of the names of every field belonging to that class
---@param class string Name of the class
---@return string[] fields Field names
---@nodiscard
---@[deprecated("Field reflection related functions no longer work: TIS removed reflection API")]
Reflection.getClassFieldNames = function(class)
    error("TIS removed reflection API, this module no longer works.")
end

---Returns the value of an object's field by name.
---This can retrieve field values even from objects of unexposed classes.
---It also works for exposed classes however it is less performant than the regular syntax.
---@param object any The object
---@param name string The name of the field
---@return any value The value of the field.
---@nodiscard
---@[deprecated("Field reflection related functions no longer work: TIS removed reflection API")]
Reflection.getField = function(object, name)
    error("TIS removed reflection API, this module no longer works.")
end

---Returns whether the specified callframe has a local variable by that name.
---@param callframeOffset integer How many callframes downwards to search for the local.
---@param name string The name of the local variable.
---@return boolean hasLocalVariable Whether the callframe had a local variable by that name.
---@nodiscard
Reflection.hasLocal = function(callframeOffset, name)
    local coroutine = getCurrentCoroutine()
    local callframe = getCoroutineCallframeStack(
        coroutine, getCallframeTop(coroutine) - 3 - callframeOffset)

    for i = 0, getLocalVarCount(callframe) - 1 do
        if getLocalVarName(callframe, i) == name then
            return true
        end
    end

    return false
end

---Returns the value of a local variable by its name.
---@param callframeOffset integer How many callframes downwards to search for the local.
---@param name string The name of the local variable.
---@return any value The value of the local variable, or nil if there was no such local. A non-existent local is indistinguishable from a local containing the value nil.
---@nodiscard
Reflection.getLocalValue = function(callframeOffset, name)
    local coroutine = getCurrentCoroutine()
    local localIndex = -1
    local callframe = getCoroutineCallframeStack(
        coroutine, getCallframeTop(coroutine) - 3 - callframeOffset)

    for i = 0, getLocalVarCount(callframe) - 1 do
        if getLocalVarName(callframe, i) == name then
            localIndex = i
            break
        end
    end

    if localIndex == -1 then
        return nil
    end

    local stackIndex = getLocalVarStackIndex(callframe, localIndex)
    return getCoroutineObjStack(coroutine, stackIndex)
end

---Returns the name of a local variable by its value.
---@param callframeOffset integer How many callframes downwards to search for the local.
---@param value any The value of the local to search for.
---@return string? name The name of the first local variable containing the value, or nil if no local variable containing the value could be found.
---@nodiscard
Reflection.getLocalName = function(callframeOffset, value)
    local coroutine = getCurrentCoroutine()
    local callframe = getCoroutineCallframeStack(
        coroutine, getCallframeTop(coroutine) - 3 - callframeOffset)

    for i = 0, getLocalVarCount(callframe) - 1 do
        if getCoroutineObjStack(coroutine, getLocalVarStackIndex(callframe, i)) == value then
            return getLocalVarName(callframe, i)
        end
    end

    return nil
end

---Returns a table containing all of the local variabless in a callframe.
---@param callframeOffset integer How many callframes downwards to get locals from.
---@return table<string, any> locals The local variables in the callframe.
---@nodiscard
Reflection.getLocals = function(callframeOffset)
    local coroutine = getCurrentCoroutine()
    local callframe = getCoroutineCallframeStack(
        coroutine, getCallframeTop(coroutine) - 3 - callframeOffset)

    local locals = {}
    for i = 0, getLocalVarCount(callframe) - 1 do
        locals[getLocalVarName(callframe, i)] = getCoroutineObjStack(coroutine, getLocalVarStackIndex(callframe, i))
    end

    return locals
end

---@deprecated Renamed to getField in 42-1.4.0
Reflection.getUnexposedObjectField = Reflection.getField

return Reflection