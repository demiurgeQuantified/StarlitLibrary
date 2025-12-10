local Bitwise = require("Starlit/utils/Bitwise")

---@type {[integer]: integer}
local cache = {}

local function clearCache()
    cache = {}
end

-- clear the cache every now and then so it doesn't grow infinitely
Events.EveryDays.Add(clearCache)

---.. versionadded:: v1.5.0
---
---The ZombieIds module provides persistent identifiers for zombies.
---The IDs are guaranteed to be reasonably unique, and stable between library versions. 
---Using identifiers for zombies is often important as their objects are pooled, so object identity comparisons are not reliable;
---the same IsoZombie object used for one zombie may be reused for another zombie later.
---
---Compared to other libraries that provide similar zombie ids, I have found this to be the fastest implementation by far.
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