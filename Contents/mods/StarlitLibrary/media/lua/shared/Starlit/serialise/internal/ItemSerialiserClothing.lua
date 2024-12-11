local ItemSerialiser = require("Starlit/serialise/internal/ItemSerialiser")
local PatchSerialiser = require("Starlit/serialise/internal/PatchSerialiser")

---@class ClothingPatch
---@field conditionGain number

---@class Starlit.SerialisedItemClothing : Starlit.SerialisedItem
---@field saveType 5
---@field spriteName string
---@field dirtiness number
---@field bloodLevel number
---@field wetness number
---@field patches table<integer, Starlit.SerialisedPatch>

local ItemSerialiserClothing = {}

---@param clothing Clothing
---@return Starlit.SerialisedItemClothing
---@nodiscard
ItemSerialiserClothing.serialise = function(clothing)
    local serialised = ItemSerialiser.serialise(clothing)

    -- TODO: why do they come out a different colour sobs

    ---@cast serialised Starlit.SerialisedItemClothing
    serialised.spriteName = clothing:getSpriteName()
    serialised.dirtiness = clothing:getDirtyness()
    serialised.bloodLevel = clothing:getBloodLevel()
    serialised.wetness = clothing:getWetness()
    -- can't set last wetness update
    serialised.patches = {}
    -- TODO convert BloodBodyPartType into a table at lua load
    for i = 0, BloodBodyPartType.MAX:ordinal() - 1 do
        local patch = clothing:getPatchType(BloodBodyPartType.FromIndex(i))
        if patch then
            serialised.patches[i] = PatchSerialiser.serialise(patch)
            -- hack lol
            serialised.condition = serialised.condition - patch.conditionGain
        end
    end


    return serialised
end

---@param serialised Starlit.SerialisedItemClothing
---@return Clothing?
---@nodiscard
ItemSerialiserClothing.deserialise = function(serialised)
    local clothing = ItemSerialiser.deserialise(serialised) --[[@as Clothing?]]
    if not clothing then
        return nil
    end

    clothing:setSpriteName(serialised.spriteName)
    clothing:setDirtyness(serialised.dirtiness)
    clothing:setBloodLevel(serialised.bloodLevel)
    clothing:setWetness(serialised.wetness)
    for i = 0, BloodBodyPartType.MAX:ordinal() - 1 do
        local serialisedPatch = serialised.patches[i]
        if serialisedPatch then
            local bodyPartType = BloodBodyPartType.FromIndex(i)
            PatchSerialiser.deserialise(serialisedPatch, clothing, bodyPartType)
        end
    end

    return clothing
end

return ItemSerialiserClothing