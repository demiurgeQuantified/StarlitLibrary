---@class ClothingPatch
---@field tailorLvl integer
---@field hasHole boolean

---@class Starlit.SerialisedPatch
---@field fabricType integer
---@field tailorLevel integer
---@field hasHole boolean

---@type {integer : InventoryItem}
local FABRIC_ITEMS = {
    [1] = InventoryItemFactory.CreateItem("Base.RippedSheets"),
    [2] = InventoryItemFactory.CreateItem("Base.DenimStrips"),
    [3] = InventoryItemFactory.CreateItem("Base.LeatherStrips")
}

-- HACK to add the patch with a character object so that the effects of tailoring level are applied
---@type IsoSurvivor
local tempCharacter
Events.OnPostMapLoad.Add(function(cell)
    ---@diagnostic disable-next-line: param-type-mismatch
    tempCharacter = IsoSurvivor.new(nil)
    -- avoid any possible side effects just in case
    getCell():getSurvivorList():remove(tempCharacter)
end)


local PatchSerialiser = {}

---@param patch ClothingPatch
---@return Starlit.SerialisedPatch
---@nodiscard
PatchSerialiser.serialise = function(patch)
    return {
        fabricType = patch:getFabricType(),
        tailorLevel = patch.tailorLvl,
        hasHole = patch.hasHole,
    }
end

---@param serialised Starlit.SerialisedPatch
---@param clothing Clothing
---@param bodyPartType BloodBodyPartType
PatchSerialiser.deserialise = function(serialised, clothing, bodyPartType)
    tempCharacter:setPerkLevelDebug(Perks.Tailoring, serialised.tailorLevel)
    if serialised.hasHole then
        clothing:getVisual():setHole(bodyPartType)
    end
    clothing:addPatch(tempCharacter, bodyPartType, FABRIC_ITEMS[serialised.fabricType])
end

return PatchSerialiser