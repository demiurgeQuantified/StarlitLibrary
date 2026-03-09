---Global module mostly used to cache frequently used objects
local Globals = {}

---@type IsoWorld
Globals.world = getWorld()
---@type ClimateManager
Globals.climateManager = getClimateManager()
---@type Core
Globals.core = getCore()
---@type IsoPuddles
Globals.puddles = getPuddlesManager()
---@type TextManager
Globals.textManager = getTextManager()
---@type ScriptManager
Globals.scriptManager = getScriptManager()
---@type boolean
Globals.isServer = isServer()
---@type boolean
Globals.isClient = isClient()
---@type boolean
Globals.isSingleplayer = not Globals.isServer and not Globals.isClient
---@type boolean
Globals.isDebug = getDebug()

---@type GameTime?
Globals.gameTime = nil
Events.OnGameTimeLoaded.Add(function() Globals.gameTime = getGameTime() end)

---@type IsoCell?
Globals.cell = nil
Events.OnPostMapLoad.Add(function(cell) Globals.cell = cell end)

return Globals