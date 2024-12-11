local ItemSerialiser = require("Starlit/serialise/internal/ItemSerialiser")

---@class Moveable
---@field customItem string?

---@class Starlit.SerialisedItemMoveable : Starlit.SerialisedItem
---@field saveType 10
---@field worldSprite string
---@field isLight boolean
---@field lightUseBattery boolean?
---@field lightHasBattery boolean?
---@field lightBulbItem string?
---@field lightPower number?
---@field lightDelta number?
---@field lightColour Starlit.Colour?

local ItemSerialiserMoveable = {}

---@param moveable Moveable
---@return Starlit.SerialisedItemMoveable
---@nodiscard
ItemSerialiserMoveable.serialise = function(moveable)
    local serialised = ItemSerialiser.serialise(moveable)

    ---@cast serialised Starlit.SerialisedItemMoveable
    serialised.worldSprite = moveable:getWorldSprite()
    serialised.isLight = moveable:isLight()
    if serialised.isLight then
        serialised.lightUseBattery = moveable:isLightUseBattery()
        serialised.lightHasBattery = moveable:isLightHasBattery()
        serialised.lightBulbItem = moveable:getLightBulbItem()
        serialised.lightPower = moveable:getLightPower()
        serialised.lightDelta = moveable:getLightDelta()
        serialised.lightColour = {moveable:getLightR(), moveable:getLightG(), moveable:getLightB()}
    end

    return serialised
end

---@param serialised Starlit.SerialisedItemMoveable
---@return Moveable?
---@nodiscard
ItemSerialiserMoveable.deserialise = function(serialised)
    local moveable = ItemSerialiser.deserialise(serialised) --[[@as Moveable?]]
    if not moveable then
        return nil
    end

    moveable:setWorldSprite(serialised.worldSprite)
    moveable:ReadFromWorldSprite(serialised.worldSprite)
    if not moveable.customItem
            and serialised.worldSprite ~= ""
            and moveable:getType() ~= serialised.worldSprite then
        moveable:setType(serialised.worldSprite)
    end

    moveable:setLight(serialised.isLight)
    if serialised.isLight then
        moveable:setLightUseBattery(serialised.lightUseBattery)
        moveable:setLightHasBattery(serialised.lightHasBattery)
        moveable:setLightBulbItem(serialised.lightBulbItem)
        moveable:setLightPower(serialised.lightPower)
        moveable:setLightDelta(serialised.lightDelta)
        moveable:setLightR(serialised.lightColour[0])
        moveable:setLightG(serialised.lightColour[1])
        moveable:setLightB(serialised.lightColour[2])
    end

    return moveable
end

return ItemSerialiserMoveable