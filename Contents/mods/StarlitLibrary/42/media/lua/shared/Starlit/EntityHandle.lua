local TaskManager = require("Starlit/TaskManager")


local TASK_CHAIN = "starlit.entityhandle"

TaskManager.addTaskChain(TASK_CHAIN)


-- maximum number of entities to check for aliveness each tick
-- this isn't that expensive so it can be fairly high, but if it's too high it may not actually save performance
local MAX_ENTITY_CHECKS_TICK = 256


---@namespace starlit


---Safe handle to a game entity, accounting for the entity unloading or being reused.
---@class EntityHandle<T: GameEntity>
---
---The contained entity.
---It is recommended to use :lua:meth:`get()` to access the entity instead.
---@field entity T | nil
---
---Cache of entity id to verify that the entity has not changed.
---@field _id number
local __GameEntityHandle = {}
__GameEntityHandle.__index = __GameEntityHandle


---Returns the contained entity.
---Throws an exception if the handle is empty.
---@return GameEntity
---@nodiscard
function __GameEntityHandle:get()
    assert(not self:isEmpty(), "tried to access empty GameEntityHandle")
    ---@cast self.entity -nil
    return self.entity
end


---Whether the contained entity still exists.
---An empty handle will never be non-empty again.
---@return boolean
---@nodiscard
function __GameEntityHandle:isEmpty()
    if not self.entity then
        return true
    end

    
    local id = self.entity:getEntityNetID()
    if id == -1 or id ~= self._id then
        return true
    end

    return false
end


---@generic T: GameEntity
---@type {[T] : EntityHandle<T>}
local handleCache = {}


---@async
local function releaseEmptyHandles()
    local iterations = 0
    while true do
        for k, handle in pairs(handleCache) do
            ---@cast k GameEntity
            ---@cast handle EntityHandle
            if handle:isEmpty() then
                handle.entity = nil
                handleCache[k] = nil
            end

            iterations = iterations + 1
            if iterations > MAX_ENTITY_CHECKS_TICK then
                coroutine.yield(TaskManager.TaskResult.CONTINUE)
                iterations = 0
            end
        end

        coroutine.yield(TaskManager.TaskResult.CONTINUE)
        iterations = 0
    end
end

TaskManager.addTask(
    TASK_CHAIN,
    coroutine.wrap(releaseEmptyHandles)
)


---.. versionadded:: v1.5.0
local EntityHandle = {}


---Gets a handle for the passed entity.
---@generic T: GameEntity
---@param entity T Entity to get a handle for.
---@return EntityHandle<T> handle Handle for the entity.
---@nodiscard
function EntityHandle.get(entity)
    local handle = handleCache[entity]

    if not handle or handle:isEmpty() then
        handle = setmetatable(
            {
                entity = entity,
                _id = entity:getEntityNetID()
            },
            __GameEntityHandle
        ) ---@as EntityHandle<T>
        handleCache[entity] = handle
    end

    return handle
end


return EntityHandle