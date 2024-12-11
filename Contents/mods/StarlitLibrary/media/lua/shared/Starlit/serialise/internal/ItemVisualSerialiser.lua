---@class Starlit.SerialisedItemVisual
---@field fullType string
---@field alternateModelName string
---@field clothingItemName string
---@field baseTexture integer
---@field textureChoice integer
---@field hue number
---@field tint [number, number, number]?
---@field decal string?
---@field blood table<integer, number>
---@field dirt table<integer, number>
---@field holes table<integer, boolean>
---@field basicPatches table<integer, boolean>
---@field denimPatches table<integer, boolean>
---@field leatherPatches table<integer, boolean>

local ItemVisualSerialiser = {}

---@param visual ItemVisual
---@return Starlit.SerialisedItemVisual
---@nodiscard
ItemVisualSerialiser.serialise = function(visual)
    local luaTint
    local tint = visual:getTint()
    if tint then
        local tintR = tint:getRedFloat()
        local tintG = tint:getGreenFloat()
        local tintB = tint:getBlueFloat()
        luaTint = {tintR, tintG, tintB}
    end

    local clothingItem = visual:getClothingItem()

    ---@type Starlit.SerialisedItemVisual
    local serialised = {
        fullType = visual:getItemType(),
        alternateModelName = visual:getAlternateModelName(),
        clothingItemName = visual:getClothingItemName(),
        baseTexture = visual:getBaseTexture(),
        textureChoice = visual:getTextureChoice(),
        hue = visual:getHue(clothingItem),
        tint = luaTint,
        decal = visual:getDecal(clothingItem),
        blood = {},
        dirt = {},
        holes = {},
        basicPatches = {},
        denimPatches = {},
        leatherPatches = {}
    }

    for i = 0, BloodBodyPartType.MAX:ordinal() - 1 do
        local bodyPartType = BloodBodyPartType.FromIndex(i)
        serialised.blood[i] = visual:getBlood(bodyPartType)
        serialised.dirt[i] = visual:getDirt(bodyPartType)
        serialised.holes[i] = visual:getHole(bodyPartType) > 0
        serialised.basicPatches[i] = visual:getBasicPatch(bodyPartType) > 0
        serialised.denimPatches[i] = visual:getDenimPatch(bodyPartType) > 0
        serialised.leatherPatches[i] = visual:getLeatherPatch(bodyPartType) > 0
    end

    return serialised
end

---@param serialised Starlit.SerialisedItemVisual
---@param visual ItemVisual
ItemVisualSerialiser.deserialise = function(serialised, visual)
    visual:setItemType(serialised.fullType)
    visual:setAlternateModelName(serialised.alternateModelName)
    visual:setClothingItemName(serialised.clothingItemName)
    visual:setBaseTexture(serialised.baseTexture)
    visual:setTextureChoice(serialised.textureChoice)
    visual:setHue(serialised.hue)
    if serialised.tint then
        visual:setTint(
            ImmutableColor.new(
                unpack(serialised.tint)))
    end
    if serialised.decal then
        visual:setDecal(serialised.decal)
    end

    for i = 0, BloodBodyPartType.MAX:ordinal() - 1 do
        local bodyPartType = BloodBodyPartType.FromIndex(i)
        visual:setBlood(bodyPartType, serialised.blood[i])
        visual:setDirt(bodyPartType, serialised.dirt[i])
        if serialised.holes[i] then
            visual:setHole(bodyPartType)
        end
        if serialised.basicPatches[i] then
            visual:setBasicPatch(bodyPartType)
        end
        if serialised.denimPatches[i] then
            visual:setDenimPatch(bodyPartType)
        end
        if serialised.leatherPatches[i] then
            visual:setLeatherPatch(bodyPartType)
        end
    end
end

return ItemVisualSerialiser