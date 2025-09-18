local IsoObjectUtils = {}

---@type IsoCell
local CELL
Events.OnPostMapLoad.Add(function (_cell, x, y)
    CELL = _cell
end)

local MIN_HEIGHT = -32

---Adds and connects a square at the given coordinates.
---@param x integer X world coordinate
---@param y integer Y world coordinate
---@param z integer Z world coordinate
---@return IsoGridSquare square The square that was added
IsoObjectUtils.addSquare = function(x, y, z)
    if z < 0 and z % 2 == 1 then -- negative odd number
        -- prevent min level from becoming odd
        -- if it does, when the next lowest level is created its lighting will be severely bugged
        local chunk = CELL:getChunkForGridSquare(x, y, z)
        local minLevel = chunk:getMinLevel()
        if minLevel < z - 1 then
            chunk:setMinMaxLevel(z - 1, chunk:getMaxLevel())
        end
    end
    return CELL:createNewGridSquare(x, y, z, true)
end

---Gets or creates a square at the given coordinates.
---@param x integer X world coordinate
---@param y integer Y world coordinate
---@param z integer Z world coordinate
---@return IsoGridSquare square The square at the location
IsoObjectUtils.getOrCreateSquare = function(x, y, z)
    return getSquare(x, y, z) or IsoObjectUtils.addSquare(x, y, z)
end

---Removes a single wall from a square.
---If the wall is a combined north and west wall sprite, the other direction will be split so it remains.
---@param square IsoGridSquare The square to remove a wall from.
---@param side "north"|"west" Which direction wall to remove.
---@param removeAttached boolean? Whether to remove objects attached to the wall. Defaults to true.
IsoObjectUtils.removeWall = function(square, side, removeAttached)
    removeAttached = removeAttached or true
    local wall = square:getWall(side == "north")
    if wall then
        local properties = wall:getProperties()
        local wantedWall = side == "north" and "CornerWestWall" or "CornerNorthWall"
        if properties:Is(wantedWall) then
            -- FIXME: this deletes all the dirt on the wall
            local newWall = IsoObject.getNew(
                square, properties:Val(wantedWall), "", false)
            square:transmitAddObjectToSquare(newWall, -1)
        end
        square:transmitRemoveItemFromSquare(wall)

        if not removeAttached then
            return
        end

        IsoObjectUtils.removeAll(square,
                                 side == "north" and IsoFlagType.attachedN or IsoFlagType.attachedW)
    end
end

---Removes the floor from a square.
---@param square IsoGridSquare The square to remove the floor from.
---@param removeAttached boolean? Whether to remove objects attached to the floor. Defaults to true.
IsoObjectUtils.removeFloor = function(square, removeAttached)
    removeAttached = removeAttached or true
    square:transmitRemoveItemFromSquare(square:getFloor())

    if not removeAttached then return end
    IsoObjectUtils.removeAll(square, IsoFlagType.attachedFloor)
end

---Returns the first object on a square with a given flag.
---@param square IsoGridSquare The square to search.
---@param flag IsoFlagType The flag to search for.
---@return IsoObject? object An object with the flag, if any.
---@nodiscard
IsoObjectUtils.getFirst = function(square, flag)
    local objects = square:getLuaTileObjectList() --[=[@as IsoObject[] ]=]
    for i = 1, #objects do
        local object = objects[i]
        if object:getProperties():Is(flag) then
            return object
        end
    end
end

---Removes all objects on a square with a given flag.
---@param square IsoGridSquare The square to remove objects from.
---@param flag IsoFlagType The flag to remove objects with.
IsoObjectUtils.removeAll = function(square, flag)
    local objects = square:getLuaTileObjectList() --[=[@as IsoObject[] ]=]
    for i = #objects, 1, -1 do
        local object = objects[i]
        if object:getProperties():Is(flag) then
            square:transmitRemoveItemFromSquare(object)
        end
    end
end

---Returns true if a square is in the playable area. The playable area is any space the player can occupy.
---Does not check if the square is actually reachable or blocked by objects.
---@param square IsoGridSquare The square to check.
---@return boolean playable Whether the square is in the playable area.
---@nodiscard
IsoObjectUtils.isInPlayableArea = function(square)
    if square:hasFloor() then return true end
    local x, y = square:getX(), square:getY()
    for z = square:getZ() - 1, MIN_HEIGHT, -1 do
        local lowerSquare = getSquare(x, y, z)
        if not lowerSquare then
            return false
        end
        if lowerSquare:hasFloor() then
            return true
        end
    end
    return false
end

---Returns a wall on a specific side on the square.
---@param square IsoGridSquare The square to search.
---@param side "north"|"west"|"northwest"|"southeast" The side wall to find.
---@return IsoObject? wall The wall, if any.
---@nodiscard
IsoObjectUtils.getWall = function(square, side)
    if side == "northwest" then
        return square:getWallNW()
    elseif side == "southeast" then
        return square:getWallSE()
    end

    -- TODO: this can probably be optimised to not scan the object list twice
    return IsoObjectUtils.getFirst(square,
                                   side == "north" and IsoFlagType.WallN or IsoFlagType.WallW)
            or IsoObjectUtils.getFirst(square,
                                 IsoFlagType.WallNW)
end

-- TODO: some kind of way to define groups of wall sprites, which can then be added to squares
-- by specifying only the wall's direction (automatically merging into corner pieces if necessary)
-- most of the code for the object management already exists in Excavation/DiggingAPI

return IsoObjectUtils