---@namespace starlit


---Base type of Starlit class objects.
---This type does not exist in the class system, and exists only for the language server; there is no Object class.
---@class Object
---
---Class of the object.
---@field class Class<self>


---Object describing a specific class in Starlit's class system.
---@class Class<T: Object>
---
---Name of the class.
---This is not required or expected to be unique, and is primarily stored for debugging purposes.
---If you need to check the type of an object, compare by identity instead.
---@field name `T`
---
---Class that this class directly inherits from.
---There is no base type, so this is often nil.
---@field superclass Class?
---
---Initialiser function for the class.
---@field initialiser fun(obj: T, ...: ConstructorParameters<T>...)
---
---Classes that directly inherit from this class.
---@field subclasses Class[]
---
---Metatable of instances.
---@field metatable metatable
local __Class = {}
__Class.__index = __Class


local Class = {}


---Determines whether an object is an instance of this class.
---@param object starlit.Object Object to test.
---@return TypeGuard<T> # True if the object's class is this class or a subclass of this class.
---@nodiscard
function __Class:isInstance(object)
    ---@type Class | nil
    local class = object.class

    while class ~= nil do
        if class == self then
            return true
        end
    
        class = class.superclass
    end

    return false
end


---FIXME: subclass initialisers are not type checked
---Creates a new class inheriting from this one.
---@generic T2: T
---@[constructor("__init", "starlit.Object")]
---@param name `T2` Name of the new class.
---@param index table Class index table. Equivalent to the __index field of a metatable.
---@return Class<T2> class The created class.
function __Class:newSubclass(name, index)
    local subclass = Class.newClass(name, index)

    subclass.superclass = self
    setmetatable(index, self.metatable)

    self.subclasses[#self.subclasses + 1] = subclass

    return subclass
end


---@param ... ConstructorParameters<T>...
---@return T
function __Class:instantiate(...)
    local o = setmetatable({}, self.metatable)

    self.initialiser(o, ...)

    return o
end


---Creates a new class.
---@generic T: Object
---@[constructor("__init", "starlit.Object")]
---@param name `T` Name of the class.
---@param index table Class index table. Equivalent to the __index field of a metatable.
---@return Class<T> class The created class.
---@nodiscard
function Class.newClass(name, index)
    local class = setmetatable({
        name = name,
        subclasses = table.newarray(),
        metatable = {
            __index = index
        },
        initialiser = index.__init or function() end
    }, __Class)

    index.class = class

    return class
end


return Class