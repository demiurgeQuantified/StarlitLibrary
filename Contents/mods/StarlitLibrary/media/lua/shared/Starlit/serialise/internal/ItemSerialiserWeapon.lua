local ItemSerialiser = require("Starlit/serialise/internal/ItemSerialiser")

---@class Starlit.SerialisedItemWeapon : Starlit.SerialisedItem
---@field saveType 1
---@field maxRange number
---@field minRangeRanged number
---@field clipSize integer
---@field minDamage number
---@field maxDamage number
---@field recoilDelay integer
---@field aimingTime integer
---@field reloadTime integer
---@field hitChance integer
---@field minAngle number
---@field scope string? Full type
---@field clip string? Full type
---@field recoilPad string? Full type
---@field sling string? Full type
---@field stock string? Full type
---@field canon string? Full type
---@field explosionTimer integer
---@field maxAngle number
---@field bloodLevel number
---@field containsClip boolean
---@field roundChambered boolean
---@field isJammed boolean
---@field weaponSprite string

local ItemSerialiserWeapon = {}

---@param weapon HandWeapon
---@return Starlit.SerialisedItemWeapon
---@nodiscard
ItemSerialiserWeapon.serialise = function(weapon)
    local serialised = ItemSerialiser.serialise(weapon)

    ---@cast serialised Starlit.SerialisedItemWeapon
    serialised.maxRange = weapon:getMaxRange()
    serialised.minRangeRanged = weapon:getMinRangeRanged()
    serialised.clipSize = weapon:getClipSize()
    serialised.minDamage = weapon:getMinDamage()
    serialised.maxDamage = weapon:getMaxDamage()
    serialised.recoilDelay = weapon:getRecoilDelay()
    serialised.aimingTime = weapon:getAimingTime()
    serialised.reloadTime = weapon:getReloadTime()
    serialised.hitChance = weapon:getHitChance()
    serialised.minAngle = weapon:getMinAngle()

    local scope = weapon:getScope()
    if scope then
        serialised.scope = scope:getFullType()
    end

    local clip = weapon:getClip()
    if clip then
        serialised.clip = clip:getFullType()
    end

    local recoilPad = weapon:getRecoilpad()
    if recoilPad then
        serialised.recoilPad = recoilPad:getFullType()
    end

    local sling = weapon:getSling()
    if sling then
        serialised.sling = sling:getFullType()
    end

    local stock = weapon:getStock()
    if stock then
        serialised.stock = stock:getFullType()
    end

    local canon = weapon:getCanon()
    if canon then
        serialised.canon = canon:getFullType()
    end

    serialised.explosionTimer = weapon:getExplosionTimer()
    serialised.maxAngle = weapon:getMaxAngle()
    serialised.bloodLevel = weapon:getBloodLevel()
    serialised.containsClip = weapon:isContainsClip()
    serialised.roundChambered = weapon:isRoundChambered()
    serialised.isJammed = weapon:isJammed()
    serialised.weaponSprite = weapon:getWeaponSprite()

    return serialised
end

---@param serialised Starlit.SerialisedItemWeapon
---@return HandWeapon?
---@nodiscard
ItemSerialiserWeapon.deserialise = function(serialised)
    local weapon = ItemSerialiser.deserialise(serialised) --[[@as HandWeapon]]
    if not weapon then
        return nil
    end

    weapon:setMaxRange(serialised.maxRange)
    weapon:setMinRangeRanged(serialised.minRangeRanged)
    weapon:setClipSize(serialised.clipSize)
    weapon:setMinDamage(serialised.minDamage)
    weapon:setMaxDamage(serialised.maxDamage)
    weapon:setRecoilDelay(serialised.recoilDelay)
    weapon:setAimingTime(serialised.aimingTime)
    weapon:setReloadTime(serialised.reloadTime)
    weapon:setHitChance(serialised.hitChance)
    weapon:setMinAngle(serialised.minAngle)

    -- TODO: nil check the items so we can log if the types are invalid
    if serialised.scope then
        weapon:attachWeaponPart(
            InventoryItemFactory.CreateItem(serialised.scope) --[[@as WeaponPart]],
            false)
    end

    if serialised.clip then
        weapon:attachWeaponPart(
            InventoryItemFactory.CreateItem(serialised.clip) --[[@as WeaponPart]],
            false)
    end

    if serialised.recoilPad then
        weapon:attachWeaponPart(
            InventoryItemFactory.CreateItem(serialised.recoilPad) --[[@as WeaponPart]],
            false)
    end

    if serialised.sling then
        weapon:attachWeaponPart(
            InventoryItemFactory.CreateItem(serialised.sling) --[[@as WeaponPart]],
            false)
    end

    if serialised.stock then
        weapon:attachWeaponPart(
            InventoryItemFactory.CreateItem(serialised.stock) --[[@as WeaponPart]],
            false)
    end

    if serialised.canon then
        weapon:attachWeaponPart(
            InventoryItemFactory.CreateItem(serialised.canon) --[[@as WeaponPart]],
            false)
    end

    weapon:setExplosionTimer(serialised.explosionTimer)
    weapon:setMaxAngle(serialised.maxAngle)
    weapon:setBloodLevel(serialised.bloodLevel)
    weapon:setContainsClip(serialised.containsClip)
    weapon:setRoundChambered(serialised.roundChambered)
    weapon:setJammed(serialised.isJammed)
    weapon:setWeaponSprite(serialised.weaponSprite)

    return weapon
end

return ItemSerialiserWeapon