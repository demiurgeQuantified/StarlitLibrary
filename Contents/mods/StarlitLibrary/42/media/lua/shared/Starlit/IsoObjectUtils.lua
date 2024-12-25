local IsoObjectUtils = {}

---Adds and connects a square at the given coordinates.
---@param x integer X world coordinate
---@param y integer Y world coordinate
---@param z integer Z world coordinate
---@return IsoGridSquare square The square that was added
IsoObjectUtils.addSquare = function(x, y, z)
    local square = IsoGridSquare.getNew(nil, nil, x, y, z)
    getCell():ConnectNewSquare(square, true)
    return square
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
IsoObjectUtils.removeWall = function(square, side)
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
    end
end

-- TODO: some kind of way to define groups of wall sprites, which can then be added to squares
-- by specifying only the wall's direction (automatically merging into corner pieces if necessary)
-- most of the code for the object management already exists in Excavation/DiggingAPI

return IsoObjectUtils