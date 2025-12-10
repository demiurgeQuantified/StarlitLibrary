---@namespace starlit


---Safe handle to a game entity, accounting for the entity unloading or being reused.
---@class EntityHandle<T: GameEntity>
---
---The contained entity.
---It is recommended to use :lua:meth:`get()` to access the entity instead.
---@field _entity T
---
---Cache of entity id to verify that the entity has not changed.
---@field _id number
local __GameEntityHandle = {}
__GameEntityHandle.__index = __GameEntityHandle


---Returns the contained entity, or nil if it has unloaded.
---@return T? entity
---@nodiscard
function __GameEntityHandle:get()
    local id = self._entity:getEntityNetID()
    if id == -1 or id ~= self._id then
        return nil
    end

    return self._entity
end


---.. versionadded:: v1.5.0
---
---Module managing entity handles.
local EntityHandle = {}


---Gets a handle for the passed entity.
---@generic T: GameEntity
---@param entity T Entity to get a handle for.
---@return EntityHandle<T> handle Handle for the entity.
---@nodiscard
function EntityHandle.get(entity)
    return setmetatable(
        {
            _entity = entity,
            _id = entity:getEntityNetID()
        },
        __GameEntityHandle
    )
end


return EntityHandle