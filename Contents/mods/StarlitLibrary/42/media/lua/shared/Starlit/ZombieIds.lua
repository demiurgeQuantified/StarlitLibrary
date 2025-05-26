local Bitwise = require("Starlit/utils/Bitwise")

---@type {[integer]: integer}
local cache = {}

local function clearCache()
    cache = {}
end

-- clear the cache every now and then so it doesn't grow infinitely
Events.EveryDays.Add(clearCache)

local ZombieIds = {}

---Returns the ID of a zombie.
---@param zombie IsoZombie The zombie.
---@return integer id The zombie's id.
---@nodiscard
function ZombieIds.get(zombie)
    local outfitId = zombie:getPersistentOutfitID()

    if not cache[outfitId] then
        cache[outfitId] = Bitwise.set(outfitId, 16, true)
    end

    return cache[outfitId]
end

return ZombieIds