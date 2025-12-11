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


---@param zombie IsoZombie
local function removeZombieDataIfNeeded(zombie)
    local id = ZombieIds.get(zombie)
    if modData[id] then
        modData[id] = nil
    end
end

Events.OnZombieDead.Add(removeZombieDataIfNeeded)

---.. versionadded:: v1.5.0
---
---Provides persistent storage associated with a specific zombie, similar to mod data.
---Zombie mod data, unlike mod data belonging to other objects, is not suitable for this usage as it is not persistent.
---Like mod data, zombie data cannot store objects or functions, only POD.
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