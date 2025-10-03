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


---Creates a new class inheriting from this one.
---@generic T2: T
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


-- TODO: preferably initialisers would be a part of the Class class, but there doesn't seem to be a typesafe way to do this
--  the initialiser parameters could be generics in the class definition however this results in very lengthy specialisation names
--  other than that, storing the initialiser inside the class is not possible while ensuring type checking

---Creates a constructor for a class.
---Initialisers are separated from constructors as it enables reuse.
---
---There is no requirement for initialisers to be accessible, 
---but it is conventional to store the initialiser in the __init field of the class's static table
---so that inheriting classes may reuse it.
---@generic T, T2...
---@param class Class<T> Class to create a constructor for.
---@param initialiser fun(object: T, ...: T2...): nil Initialiser function for the constructor.
---@return fun(...: T2...): T constructor Constructor using the initialiser passed.
---@nodiscard
function Class.newConstructor(class, initialiser)
    return function(...)
        local object = setmetatable({}, class.metatable)

        initialiser(object, ...)

        return object
    end
end


---Creates a new class.
---@generic T: Object
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
        }
    }, __Class)

    index.class = class

    return class
end


return Class