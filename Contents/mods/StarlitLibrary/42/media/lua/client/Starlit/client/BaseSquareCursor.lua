local CORE = getCore()
---@type IsoCell
local CELL
Events.OnPostMapLoad.Add(function(cell, x, y)
    CELL = cell
end)

---Base class for square cursors.
---@class starlit.BaseSquareCursor
---@field player IsoPlayer The player the cursor belongs to.
---@field _isStarlitCursor true
---@field package _selectedThisTick boolean
---@field package _isValidCache boolean | nil
---@field package _isValidCacheSquare IsoGridSquare?
---@field xJoypad integer Current X co-ordinate of the cursor, if it is controlled by a joypad. -1 means uninitialised or not a joypad player.
---@field yJoypad integer Current Y co-ordinate of the cursor, if it is controlled by a joypad. -1 means uninitialised or not a joypad player.
---@field zJoypad integer Current Z co-ordinate of the cursor, if it is controlled by a joypad. -1 means uninitialised or not a joypad player.
local BaseSquareCursor = {}
BaseSquareCursor.__index = BaseSquareCursor

---Called when the player clicks on a square.
---@param square IsoGridSquare The selected square.
---@param hide boolean? Whether to hide the cursor. Defaults to true.
BaseSquareCursor.select = function(self, square, hide)
    hide = hide == nil and true or hide
    self._selectedThisTick = true
    if hide then
        ---@diagnostic disable-next-line: param-type-mismatch
        CELL:setDrag(nil, self.player:getPlayerNum())
    end
end

---Called when checking if a square is valid.
---This function caches the result - in most cases you only want to override isValidInternal.
---@param square IsoGridSquare? The square to check.
---@return boolean valid Whether the square is valid.
BaseSquareCursor.isValid = function(self, square)
    if self._isValidCache == nil or square ~= self._isValidCacheSquare then
        self._isValidCacheSquare = square
        self._isValidCache = self:isValidInternal(square)
    end
    return self._isValidCache
end

---Calculates if a square is valid. Invalid squares cannot be selected.
---@param square IsoGridSquare? The square to check.
---@return boolean valid Whether the square is valid.
BaseSquareCursor.isValidInternal = function(self, square)
    return true
end

---Called every tick to render the cursor.
---@param x integer The X coordinate of the square the cursor is over.
---@param y integer The Y coordinate of the square the cursor is over.
---@param z integer The Z coordinate of the square the cursor is over.
---@param square IsoGridSquare The square the cursor is over.
BaseSquareCursor.render = function(self, x, y, z, square)
    local hc = CORE:getGoodHighlitedColor()
    if not self:isValid(square) then
        hc = CORE:getBadHighlitedColor()
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

---Called when a joypad button is pressed.
---For most cases it makes more sense to override the onJoypadPress functions instead.
---@param joypadIndex integer
---@param joypadData JoypadData
---@param button integer
BaseSquareCursor.onJoypadPressButton = function(self, joypadIndex, joypadData, button)
    if button == Joypad.AButton then
        self:onJoypadPressA(joypadData)
    elseif button == Joypad.BButton then
        self:onJoypadPressB(joypadData)
    elseif button == Joypad.YButton then
        self:onJoypadPressY(joypadData)
    elseif button == Joypad.LBumper then
        self:onJoypadPressLB(joypadData)
    elseif button == Joypad.RBumper then
        self:onJoypadPressRB(joypadData)
    end
end

---Called when down is presssed on the joypad's directional pad.
---@param joypadData JoypadData
BaseSquareCursor.onJoypadDirDown = function(self, joypadData)
    self.yJoypad = self.yJoypad + 1;
end

---Called when up is presssed on the joypad's directional pad.
---@param joypadData JoypadData
BaseSquareCursor.onJoypadDirUp = function(self, joypadData)
    self.yJoypad = self.yJoypad - 1;
end

---Called when right is presssed on the joypad's directional pad.
---@param joypadData JoypadData
BaseSquareCursor.onJoypadDirRight = function(self, joypadData)
    self.xJoypad = self.xJoypad + 1;
end

---Called when left is presssed on the joypad's directional pad.
---@param joypadData JoypadData
BaseSquareCursor.onJoypadDirLeft = function(self, joypadData)
    self.xJoypad = self.xJoypad - 1;
end

---Called when the joypad A button is pressed.
---@param joypadData JoypadData
BaseSquareCursor.onJoypadPressA = function(self, joypadData)
    local targetSquare = getSquare(self.xJoypad, self.yJoypad, self.zJoypad)
    if self:isValid(targetSquare) then
        self:select(targetSquare)
    end
end

---Called when the joypad B button is pressed.
---@param joypadData JoypadData
BaseSquareCursor.onJoypadPressB = function(self, joypadData)
    ---@diagnostic disable-next-line: param-type-mismatch
    CELL:setDrag(nil, joypadData.player)
end

---Called when the joypad Y button is pressed.
---@param joypadData JoypadData
BaseSquareCursor.onJoypadPressY = function(self, joypadData)
    local playerSquare = self.player:getSquare()
    self.xJoypad = playerSquare:getX()
    self.yJoypad = playerSquare:getY()
end

---Called when the joypad left bumper is pressed.
---@param joypadData JoypadData
BaseSquareCursor.onJoypadPressLB = function(self, joypadData)

end

---Called when the joypad right bumper is pressed.
---@param joypadData JoypadData
BaseSquareCursor.onJoypadPressRB = function(self, joypadData)

end

---Returns the prompt for the joypad A button.
---@return string | nil prompt Text to display as a prompt for the A button, or nil to display nothing.
BaseSquareCursor.getAPrompt = function(self)
    return getText("IGUI_Keyboard_Accept")
end

---Returns the prompt for the joypad B button.
---@return string | nil prompt Text to display as a prompt for the B button, or nil to display nothing.

BaseSquareCursor.getBPrompt = function(self)
    return getText("UI_Cancel")
end

---Returns the prompt for the joypad Y button.
---@return string | nil prompt Text to display as a prompt for the Y button, or nil to display nothing.

BaseSquareCursor.getYPrompt = function(self)
    return getText("IGUI_SetCursorToPlayerLocation")
end

---Returns the prompt for the joypad left bumper.
---@return string | nil prompt Text to display as a prompt for the left bumper, or nil to display nothing.

BaseSquareCursor.getLBPrompt = function(self)
    return nil
end

---Returns the prompt for the joypad right bumper.
---@return string | nil prompt Text to display as a prompt for the right bumper, or nil to display nothing.

BaseSquareCursor.getRBPrompt = function(self)
    return nil
end

---Creates a new BaseSquareCursor. After creation the cursor can be made active using IsoCell.setDrag().
---@param player IsoPlayer The player to create the cursor for.
---@return starlit.BaseSquareCursor cursor The cursor.
---@nodiscard
BaseSquareCursor.new = function(player)
    local o = {
        player = player,
        _isStarlitCursor = true,
        _selectedThisTick = false,
        xJoypad = -1,
        yJoypad = -1,
        zJoypad = -1
    }
    setmetatable(o, BaseSquareCursor) ---@cast o starlit.BaseSquareCursor

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
            ---@cast draggingItem starlit.BaseSquareCursor
            if isRender then
                draggingItem:render(x, y, z, square)
            end
            if (draggingItem.player:getPlayerNum() ~= 0 or (GameKeyboard.isKeyPressed("Attack/Click") and not isMouseOverUI()))
                    and draggingItem:isValid(square) then
                draggingItem:select(square)
            end
        else
            return old_DoTileBuilding(draggingItem, isRender, x, y, z, square)
        end
    end

    Events.OnDoTileBuilding2.Add(DoTileBuilding);
end)

---@type starlit.BaseSquareCursor[]
local currentCursors = table.newarray()

Events.SetDragItem.Add(function(drag, playerNum)
    -- if previous drag was a Starlit cursor, remove it from the list
    local previousDrag = CELL:getDrag(playerNum)
    if previousDrag and previousDrag._isStarlitCursor then
        for i = 1, #currentCursors do
            if currentCursors[i] == previousDrag then
                table.remove(currentCursors, i)
                break
            end
        end
    end

    -- if the new drag is a Starlit cursor, add it to the list
    if drag and drag._isStarlitCursor then
        for i = 1, #currentCursors do
            if currentCursors[i] == drag then
                return
            end
        end
        table.insert(currentCursors, drag)
    end
end)

Events.OnTick.Add(function()
    for i = 1, #currentCursors do
        currentCursors[i]._isValidCache = nil
    end
end)

return BaseSquareCursor