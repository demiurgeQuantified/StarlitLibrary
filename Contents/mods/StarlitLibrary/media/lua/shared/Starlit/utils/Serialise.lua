local Colour = require("Starlit/utils/Colour")

-- TODO: nearly everything in this file can be optimised to reduce the size of the serialised representation

---@class Starlit.SerialisedItem
---@field registryId integer
---@field saveType 0
---@field id integer
---@field uses integer
---@field condition number
---@field customColour [number, number, number, number]?
---@field itemCapacity number
---@field modData table
---@field activated boolean
---@field haveBeenRepaired integer
---@field name string
---@field extraItems string[]?
---@field customName boolean
---@field customWeight float?
---@field keyId integer
---@field taintedWater boolean
---@field remoteControlId integer
---@field remoteRange integer
---@field colour Starlit.Colour don't ask me why items have two different colours...
---@field worker string
---@field wetCooldown number
---@field favourite boolean
---@field stashMap string?
---@field infected boolean
---@field currentAmmoCount integer
---@field attachedSlot integer
---@field attachedSlotType string?
---@field attachedToModel string?
---@field maxCapacity integer
---@field recordedMediaIndex number?
---@field worldZRotation number
---@field worldScale number
---@field initialised boolean
---@field visual Starlit.SerialisedItemVisual?

---@class Starlit.SerialisedItemVisual
---@field fullType string
---@field alternateModelName string
---@field clothingItemName string
---@field tint Starlit.Colour?
---@field baseTexture integer
---@field textureChoice integer
---@field hue number
---@field decal string?
---@field blood table<integer, number>
---@field dirt table<integer, number>
---@field holes table<integer, boolean>
---@field basicPatches table<integer, boolean>
---@field denimPatches table<integer, boolean>
---@field leatherPatches table<integer, boolean>

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
---@field scope number Registry id
---@field clip number Registry id
---@field recoilPad number Registry id
---@field sling number Registry id
---@field stock number Registry id
---@field canon number Registry id
---@field explosionTimer integer
---@field maxAngle number
---@field bloodLevel number
---@field containsClip boolean
---@field roundChambered boolean
---@field isJammed boolean
---@field weaponSprite string

---@class Starlit.SerialisedItemFood : Starlit.SerialisedItem
---@field saveType 2
---@field age number
---@field lastAged number
---@field calories number
---@field proteins number
---@field lipids number
---@field carbohydrates number
---@field hungerChange number
---@field baseHunger number
---@field unhappyChange number
---@field boredomChange number
---@field thirstChange number
---@field heat number
---@field lastCookMinute integer
---@field cookingTime number
---@field cooked boolean
---@field burnt boolean
---@field isCookable boolean
---@field dangerousUncooked boolean
---@field poisonDetectionLevel integer
---@field spices string[]?
---@field poisonPower integer
---@field chef string
---@field offAge integer
---@field offageMax integer
---@field painReduction number
---@field fluReduction integer
---@field reduceFoodSickness integer
---@field poison boolean
---@field useForPoison integer
---@field freezingTime number
---@field frozen boolean
---@field rottenTime number
---@field compostTime number
---@field cookedInMicrowave boolean
---@field fatigueChange number
---@field enduranceChange number

---@param serialised Starlit.SerialisedItem
---@param food Food
local serialiseFoodProperties = function(serialised, food)
    ---@cast serialised Starlit.SerialisedItemFood
    serialised.age = food:getAge()
    serialised.lastAged = food:getLastAged()
    serialised.calories = food:getCalories()
    serialised.proteins = food:getProteins()
    serialised.lipids = food:getLipids()
    serialised.carbohydrates = food:getCarbohydrates()
    serialised.hungerChange = food:getHungChange()
    serialised.baseHunger = food:getBaseHunger()
    serialised.unhappyChange = food:getUnhappyChange()
    serialised.boredomChange = food:getBoredomChange()
    serialised.thirstChange = food:getThirstChange()
    serialised.heat = food:getHeat()
    serialised.lastCookMinute = food:getLastCookMinute()
    serialised.cookingTime = food:getCookingTime()
    serialised.cooked = food:isCooked()
    serialised.burnt = food:isBurnt()
    serialised.isCookable = food:isCookable()
    serialised.dangerousUncooked = food:isbDangerousUncooked()
    serialised.poisonDetectionLevel = food:getPoisonDetectionLevel()

    local spices = food:getSpices()
    if spices then
        serialised.spices = {}
        for i = 0, spices:size() - 1 do
            serialised.spices[i] = spices:get(i)
        end
    end

    serialised.poisonPower = food:getPoisonPower()
    serialised.chef = food:getChef()
    serialised.offAge = food:getOffAge()
    serialised.offageMax = food:getOffAgeMax()
    serialised.painReduction = food:getPainReduction()
    serialised.fluReduction = food:getFluReduction()
    serialised.reduceFoodSickness = food:getReduceFoodSickness()
    serialised.poison = food:isPoison()
    serialised.useForPoison = food:getUseForPoison()
    serialised.freezingTime = food:getFreezingTime()
    serialised.frozen = food:isFrozen()
    serialised.rottenTime = food:getRottenTime()
    serialised.compostTime = food:getCompostTime()
    serialised.cookedInMicrowave = food:isCookedInMicrowave()
    serialised.fatigueChange = food:getFatigueChange()
    serialised.enduranceChange = food:getEndChange()
    -- can't set lastFrozenUpdate
end

---@class Starlit.SerialisedItemLiterature : Starlit.SerialisedItem
---@field saveType 3
---@field numberOfPages integer
---@field alreadyReadPages integer
---@field canBeWrite boolean
---@field customPages table<integer, string>?
---@field lockedBy string?

---@param serialised Starlit.SerialisedItem
---@param literature Literature
local serialiseLiteratureProperties = function(serialised, literature)
    ---@cast serialised Starlit.SerialisedItemLiterature
    serialised.numberOfPages = literature:getNumberOfPages()
    serialised.alreadyReadPages = literature:getAlreadyReadPages()
    serialised.canBeWrite = literature:canBeWrite()

    local customPages = literature:getCustomPages()
    if customPages then
        serialised.customPages = {}
        for i = 0, customPages:size() - 1 do
            serialised.customPages[i] = customPages:get(i)
        end
    end

    serialised.lockedBy = literature:getLockedBy()
end

---@class Starlit.SerialisedItemDrainable : Starlit.SerialisedItem
---@field saveType 4
---@field usedDelta number

---@class Starlit.SerialisedItemClothing : Starlit.SerialisedItem
---@field saveType 5
---@field spriteName string
---@field dirtiness number
---@field bloodLevel number
---@field wetness number
---@field patches table<integer, Starlit.SerialisedPatch>

---@class Starlit.SerialisedPatch
---@field fabricType integer
---@field scratchDefence integer
---@field biteDefence integer
---@field hasHole boolean
---@field conditionGain integer

---@param serialised Starlit.SerialisedItem
---@param clothing Clothing
local serialiseClothingProperties = function(serialised, clothing)
    ---@cast serialised Starlit.SerialisedItemClothing
    serialised.spriteName = clothing:getSpriteName()
    serialised.dirtiness = clothing:getDirtyness()
    serialised.bloodLevel = clothing:getBloodLevel()
    serialised.wetness = clothing:getWetness()
    -- can't set last wetness update
    serialised.patches = {}
    -- TODO convert BloodBodyPartType into a table at lua load
    for i = 0, BloodBodyPartType.MAX do
        local patch = clothing:getPatchType(BloodBodyPartType.FromIndex(i))
        if patch then
            serialised.patches[i] = {
                fabricType = patch:getFabricType(),
                scratchDefence = patch:getScratchDefense(),
                biteDefence = patch:getBiteDefense(),
                conditionGain = patch.conditionGain,
                hasHole = patch.hasHole
            }
        end
    end
end

---@class Starlit.SerialisedItemContainer : Starlit.SerialisedItem
---@field saveType 6
---@field weightReduction integer

---@param serialised Starlit.SerialisedItem
---@param container InventoryContainer
local serialiseContainerProperties = function(serialised, container)
    ---@cast serialised Starlit.SerialisedItemContainer
    serialised.weightReduction = container:getWeightReduction()
end

---@class Starlit.SerialisedItemKey : Starlit.SerialisedItem
---@field saveType 8
---@field keyId integer
---@field numberOfKey integer

---@param serialised Starlit.SerialisedItem
---@param key Key
local serialiseKeyProperties = function(serialised, key)
    ---@cast serialised Starlit.SerialisedItemKey
    serialised.keyId = key:getKeyId()
    serialised.numberOfKey = key:getNumberOfKey()
end

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

---@param serialised Starlit.SerialisedItem
---@param moveable Moveable
local serialiseMoveableProperties = function(serialised, moveable)
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
end

---@class Starlit.SerialisedItemRadio : Starlit.SerialisedItem
---@field saveType 11
---@field deviceData Starlit.SerialisedDeviceData?

---@class Starlit.SerialisedDeviceData
---@field deviceName string
---@field twoWay boolean
---@field transmitRange integer
---@field micRange integer
---@field muted boolean
---@field baseVolumeRange number
---@field deviceVolume number
---@field portable boolean
---@field television boolean
---@field highTier boolean
---@field turnedOn boolean
---@field channel integer
---@field minChannelRange integer
---@field maxChannelRange integer
---@field batteryPowered boolean
---@field hasBattery boolean
---@field powerDelta number
---@field useDelta number
---@field headphoneType integer
---@field mediaIndex integer
---@field mediaType integer
---@field mediaItem string?
---@field noTransmit boolean
---@field presets Starlit.SerialisedDeviceData.Presets?

---@class Starlit.SerialisedDeviceData.Presets
---@field maxPresets integer
---@field presets table<string, integer>

---@param serialised Starlit.SerialisedItem
---@param radio Radio
local serialiseRadioProperties = function(serialised, radio)
    ---@cast serialised Starlit.SerialisedItemRadio
    local deviceData = radio:getDeviceData()
    if not deviceData then return end
    serialised.deviceData = {
        deviceName = deviceData:getDeviceName(),
        twoWay = deviceData:getIsTwoWay(),
        transmitRange = deviceData:getTransmitRange(),
        micRange = deviceData:getMicRange(),
        muted = deviceData:getMicIsMuted(),
        baseVolumeRange = deviceData:getBaseVolumeRange(),
        deviceVolume = deviceData:getDeviceVolume(),
        portable = deviceData:getIsPortable(),
        television = deviceData:getIsTelevision(),
        highTier = deviceData:getIsHighTier(),
        turnedOn = deviceData:getIsTurnedOn(),
        channel = deviceData:getChannel(),
        minChannelRange = deviceData:getMinChannelRange(),
        maxChannelRange = deviceData:getMaxChannelRange(),
        batteryPowered = deviceData:getIsBatteryPowered(),
        hasBattery = deviceData:getHasBattery(),
        powerDelta = deviceData:getPower(),
        useDelta = deviceData:getUseDelta(),
        headphoneType = deviceData:getHeadphoneType(),
        mediaIndex = deviceData:getMediaIndex(),
        mediaType = deviceData:getMediaType(),
        mediaItem = deviceData.mediaItem,
        noTransmit = deviceData:isNoTransmit(),
    }
    local devicePresets = deviceData:getDevicePresets()
    if devicePresets then
        serialised.deviceData.presets = {
            maxPresets = devicePresets:getMaxPresets(),
            presets = {}
        }
        local presets = devicePresets:getPresetsLua()
        for i = 1, #presets do
            local preset = presets[i]
            serialised.deviceData.presets.presets[preset.name] = preset.frequency
        end
    end
end

---@class Starlit.SerialisedItemAlarmClock : Starlit.SerialisedItem
---@field saveType 12
---@field alarmHour integer
---@field alarmMinute integer
---@field alarmSet boolean

---@param serialised Starlit.SerialisedItem
---@param alarmClock AlarmClock
local serialiseAlarmClockProperties = function(serialised, alarmClock)
    ---@cast serialised Starlit.SerialisedItemAlarmClock
    serialised.alarmHour = alarmClock:getHour()
    serialised.alarmMinute = alarmClock:getMinute()
    serialised.alarmSet = alarmClock:isAlarmSet()
    -- can't do ring since
end

---@class Starlit.SerialisedItemAlarmClockClothing : Starlit.SerialisedItemClothing
---@field saveType 13
---@field alarmHour integer
---@field alarmMinute integer
---@field alarmSet boolean

---@param serialised Starlit.SerialisedItem
---@param alarmClockClothing AlarmClockClothing
local serialiseAlarmClockClothingProperties = function(serialised, alarmClockClothing)
    ---@cast serialised Starlit.SerialisedItemAlarmClockClothing
    serialiseAlarmClockProperties(serialised, alarmClockClothing--[[@as AlarmClock]])
    serialiseClothingProperties(serialised, alarmClockClothing)
end

---@class Starlit.SerialisedItemMap : Starlit.SerialisedItem
---@field saveType 14
---@field mapId string

---@param serialised Starlit.SerialisedItem
---@param map MapItem
local serialiseMapProperties = function(serialised, map)
    ---@cast serialised Starlit.SerialisedItemMap
    serialised.mapId = map:getMapID()
    -- absolutely no hope of doing symbols lol
end

---@param serialised Starlit.SerialisedItem
---@param weapon HandWeapon
local serialiseHandWeaponProperties = function(serialised, weapon)
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
        serialised.scope = scope:getRegistry_id()
    end

    local clip = weapon:getClip()
    if clip then
        serialised.clip = clip:getRegistry_id()
    end

    local recoilPad = weapon:getRecoilpad()
    if recoilPad then
        serialised.recoilPad = recoilPad:getRegistry_id()
    end

    local sling = weapon:getSling()
    if sling then
        serialised.sling = sling:getRegistry_id()
    end

    local stock = weapon:getStock()
    if stock then
        serialised.stock = stock:getRegistry_id()
    end

    local canon = weapon:getCanon()
    if canon then
        serialised.canon = canon:getRegistry_id()
    end

    serialised.explosionTimer = weapon:getExplosionTimer()
    serialised.maxAngle = weapon:getMaxAngle()
    serialised.bloodLevel = weapon:getBloodLevel()
    serialised.containsClip = weapon:isContainsClip()
    serialised.roundChambered = weapon:isRoundChambered()
    serialised.isJammed = weapon:isJammed()
    serialised.weaponSprite = weapon:getWeaponSprite()
end

local Serialise = {}

---Tests if an item can be serialised without losing any information. The resulting item from serialisation and then deserialisation will be absolutely identical.
---@param item InventoryItem The item to test.
---@return boolean canSerialiseLossless True if the item can be serialised without loss. False otherwise.
---@nodiscard
Serialise.canSerialiseItemLossless = function(item)
    if item:getByteData() then
        return false
    end
    if instanceof(item, "MapItem") then
        return false
    end
    -- TODO: maybe clothing :(
    return true
end

---@param item InventoryItem The item to serialise.
---@return Starlit.SerialisedItem serialisedItem
---@nodiscard
Serialise.serialiseInventoryItem = function(item)
    ---@type Starlit.SerialisedItem
    local serialised = {
        registryId = item:getRegistry_id(),
        saveType = item:getSaveType(),
        id = item:getID(),
        uses = item:getCurrentUses(),
        condition = item:getCondition(),
        itemCapacity = item:getItemCapacity(),
        modData = copyTable(item:getModData()),
        activated = item:isActivated(),
        haveBeenRepaired = item:getHaveBeenRepaired(),
        name = item:getDisplayName(),
        -- can't do bytedata lol
        customName = item:isCustomName(),
        keyId = item:getKeyId(),
        taintedWater = item:isTaintedWater(),
        remoteControlId = item:getRemoteControlID(),
        remoteRange = item:getRemoteRange(),
        colour = {item:getColorRed(), item:getColorGreen(), item:getColorBlue()},
        worker = item:getWorker(),
        wetCooldown = item:getWetCooldown(),
        favourite = item:isFavorite(),
        infected = item:isInfected(),
        currentAmmoCount = item:getCurrentAmmoCount(),
        attachedSlot = item:getAttachedSlot(),
        attachedSlotType = item:getAttachedSlotType(),
        attachedToModel = item:getAttachedToModel(),
        maxCapacity = item:getMaxCapacity(),
        recordedMediaIndex = item:getRecordedMediaIndex(),
        worldZRotation = item.worldZRotation,
        worldScale = item.worldScale,
        initialised = item:isInitialised()
    }

    if item:IsDrainable() then
        ---@cast item DrainableComboItem
        ---@cast serialised Starlit.SerialisedItemDrainable
        serialised.usedDelta = item:getUsedDelta()
    end

    if item:isCustomColor() then
        serialised.customColour = {unpack(Colour:fromColor()), 0}
    end

    local extraItems = item:getExtraItems()
    if extraItems then
        serialised.extraItems = {}
        for i = 0, extraItems:size() - 1 do
            -- TODO: can i get registry ids?
            table.insert(serialised.extraItems, extraItems:get(i))
        end
    end

    if item:isCustomWeight() then
        serialised.customWeight = item:getActualWeight()
    end

    local stashMap = item.stashMap
    if stashMap then
        serialised.stashMap = stashMap
    end

    local visual = item:getVisual()
    if visual then
        serialised.visual = {
            fullType = visual:getItemType(),
            alternateModelName = visual:getAlternateModelName(),
            clothingItemName = visual:getClothingItemName(),
            baseTexture = visual:getBaseTexture(),
            textureChoice = visual:getTextureChoice(),
            hue = visual:getHue(visual:getClothingItem()),
            blood = {},
            dirt = {},
            holes = {},
            basicPatches = {},
            denimPatches = {},
            leatherPatches = {}
        }

        for i = 0, BloodBodyPartType.MAX do
            local bodyPartType = BloodBodyPartType.FromIndex(i)
            serialised.visual.blood[i] = visual:getBlood(bodyPartType)
            serialised.visual.dirt[i] = visual:getDirt(bodyPartType)
            serialised.visual.holes[i] = visual:getHole(bodyPartType) > 0
            serialised.visual.basicPatches[i] = visual:getBasicPatch(bodyPartType) > 0
            serialised.visual.denimPatches[i] = visual:getDenimPatch(bodyPartType) > 0
            serialised.visual.leatherPatches[i] = visual:getLeatherPatch(bodyPartType) > 0
        end
    end

    -- TODO: ugh
    if serialised.saveType == 1 then
        serialiseHandWeaponProperties(serialised, item--[[@as HandWeapon]])
    elseif serialised.saveType == 2 then
        serialiseFoodProperties(serialised, item--[[@as Food]])
    elseif serialised.saveType == 3 then
        serialiseLiteratureProperties(serialised, item--[[@as Literature]])
    elseif serialised.saveType == 5 then
        serialiseClothingProperties(serialised, item--[[@as Clothing]])
    elseif serialised.saveType == 6 then
        serialiseContainerProperties(serialised, item--[[@as InventoryContainer]])
    elseif serialised.saveType == 8 then
        serialiseKeyProperties(serialised, item--[[@as Key]])
    elseif serialised.saveType == 10 then
        serialiseMoveableProperties(serialised, item--[[@as Moveable]])
    elseif serialised.saveType == 11 then
        serialiseRadioProperties(serialised, item--[[@as Radio]])
    elseif serialised.saveType == 12 then
        serialiseAlarmClockProperties(serialised, item--[[@as AlarmClock]])
    elseif serialised.saveType == 13 then
        serialiseAlarmClockClothingProperties(serialised, item--[[@as AlarmClockClothing]])
    elseif serialised.saveType == 14 then
        serialiseMapProperties(serialised, item--[[@as MapItem]])
    end

    return serialised
end

---@param serialisedItem Starlit.SerialisedItem
---@return InventoryItem item
---@nodiscard
Serialise.deserialiseInventoryItem = function(serialisedItem)
    assert(false, "TODO: NOT YET IMPLEMENTED")
end

return Serialise