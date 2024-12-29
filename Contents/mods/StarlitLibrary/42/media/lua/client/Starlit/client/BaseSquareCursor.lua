---Base class for square cursors.
---@class Starlit.BaseSquareCursor
---@field player IsoPlayer The player the cursor belongs to.
---@field private _isStarlitCursor true
---@field private _selectedThisTick boolean
local BaseSquareCursor = {}
BaseSquareCursor.__index = BaseSquareCursor

---Called when the player clicks on a square.
---@param square IsoGridSquare The selected square.
---@param hide boolean? Whether to hide the cursor. Defaults to true.
BaseSquareCursor.select = function(self, square, hide)
    self._selectedThisTick = true
    if hide then
        ---@diagnostic disable-next-line: param-type-mismatch
        getCell():setDrag(nil, self.player:getPlayerNum())
    end
end

---Called when determining if a square is valid. Invalid squares cannot be selected and render as red.
---@param square IsoGridSquare? The square to check.
---@return boolean valid Whether the square is valid.
BaseSquareCursor.isValid = function(self, square)
    return true
end

---Called every tick to render the cursor.
---@param x integer The X coordinate of the square the cursor is over.
---@param y integer The Y coordinate of the square the cursor is over.
---@param z integer The Z coordinate of the square the cursor is over.
---@param square IsoGridSquare The square the cursor is over.
BaseSquareCursor.render = function(self, x, y, z, square)
	local hc = getCore():getGoodHighlitedColor()
	if not self:isValid(square) then
		hc = getCore():getBadHighlitedColor()
	end
	ISBuildingObject:getFloorCursorSprite():RenderGhostTileColor(x, y, z, hc:getR(), hc:getG(), hc:getB(), 0.8)
end

---Called when the player hits a key while the cursor is active.
---Override keyPressed instead if you don't want your api to have dumb names
---@param key integer
BaseSquareCursor.rotateKey = function(self, key)
    self:keyPressed(key)
end

---Called when the player hits a key while the cursor is active.
---@param key integer The key that was pressed.
BaseSquareCursor.keyPressed = function(self, key)

end

---Creates a new BaseSquareCursor. After creation the cursor can be made active using IsoCell.setDrag().
---@param player IsoPlayer The player to create the cursor for.
---@return Starlit.BaseSquareCursor cursor The cursor.
BaseSquareCursor.new = function(player)
    local o = {
        player = player,
        _isStarlitCursor = true,
        _selectedThisTick = false
    }
    setmetatable(o, BaseSquareCursor) ---@cast o Starlit.BaseSquareCursor

    return o
end

local function isMouseOverUI()
	local uis = UIManager.getUI()
	for i=1,uis:size() do
		local ui = uis:get(i-1)
		if ui:isMouseOver() then
			return true
		end
	end
	return false
end

-- must delay to OnInitGlobalModData so that server code has already loaded
Events.OnInitGlobalModData.Add(function()
    -- hack to avoid all the building code
    Events.OnDoTileBuilding2.Remove(DoTileBuilding);

    local old_DoTileBuilding = DoTileBuilding
    DoTileBuilding = function(draggingItem, isRender, x, y, z, square)
        if draggingItem._isStarlitCursor then
            ---@cast draggingItem Starlit.BaseSquareCursor
            if isRender then
                draggingItem:render(x, y, z, square)
            end
            ---@diagnostic disable-next-line: invisible
            if not draggingItem._selectedThisTick
                    and (draggingItem.player:getPlayerNum() ~= 0 or (GameKeyboard.isKeyDown("Attack/Click") and not isMouseOverUI()))
                    and draggingItem:isValid(square) then
                draggingItem:select(square)
            end
        else
            return old_DoTileBuilding(draggingItem, isRender, x, y, z, square)
        end
    end

    Events.OnDoTileBuilding2.Add(DoTileBuilding);
end)

---@type IsoCell
local CELL
Events.OnPostMapLoad.Add(function(cell, x, y)
    CELL = cell
end)

Events.OnTick.Add(function()
    for i = 0, getNumActivePlayers() do
        local drag = CELL:getDrag(i)
        if drag and drag._isStarlitCursor and drag._selectedThisTick then
            drag._selectedThisTick = false
        end
    end
end)

return BaseSquareCursor