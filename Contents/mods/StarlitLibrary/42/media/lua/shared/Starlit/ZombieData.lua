local ZombieIds = require("Starlit/ZombieIds")

---@type {version: integer, [integer]: table}
local modData

local function initModData()
    modData = ModData.getOrCreate("starlit.ZombieData")
    if modData.version and modData.version > 1 then
        error("Starlit error: ZombieData version higher than current version. Data may be corrupt or from a newer version of the library.")
    end
    modData.version = 1
end

Events.OnInitGlobalModData.Add(initModData)

---@type Callback_OnZombieDead
local function removeZombieDataIfNeeded(zombie)
    local id = ZombieIds.get(zombie)
    if modData[id] then
        modData[id] = nil
    end
end

Events.OnZombieDead.Add(removeZombieDataIfNeeded)

---Allows persistent storage of POD for zombies.
---Zombie data is a plain lua table associated with a specific zombie.
local ZombieData = {}

---Returns the zombie data for a zombie.
---@param zombie IsoZombie The zombie.
---@return table zombieData The zombie data.
---@nodiscard
function ZombieData.get(zombie)
    local id = ZombieIds.get(zombie)
    if not modData[id] then
        modData[id] = {}
    end

    return modData[id]
end

return ZombieData