local ItemVisualSerialiser = require("Starlit/serialise/internal/ItemVisualSerialiser")
local Colour = require("Starlit/utils/Colour")

local log = require("Starlit/debug/StarlitLog")

-- i forgot i can't access these fields since they're inherited sobs
-- -- prevents undefined field warnings for java field accesses
-- ---@class InventoryItem
-- ---@field worldZRotation number
-- ---@field worldScale number
-- ---@field stashMap string?

---@class Starlit.SerialisedItem
---@field fullType string
---@field saveType 0
---@field id integer
---@field uses integer
---@field condition number
---@field customColour [number, number, number, number]?
---@field itemCapacity number
---@field modData table
---@field activated boolean
---@field haveBeenRepaired integer
---@field name string?
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
-- ---@field stashMap string?
---@field infected boolean
---@field currentAmmoCount integer
---@field attachedSlot integer
---@field attachedSlotType string?
---@field attachedToModel string?
---@field maxCapacity integer
---@field recordedMediaIndex number?
-- ---@field worldZRotation number
-- ---@field worldScale number
---@field initialised boolean
---@field visual Starlit.SerialisedItemVisual?

local ItemSerialiser = {}

---@param item InventoryItem
---@return Starlit.SerialisedItem
---@nodiscard
ItemSerialiser.serialise = function(item)
    ---@type Starlit.SerialisedItem
    local serialised = {
        fullType = item:getFullType(),
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
        -- worldZRotation = item.worldZRotation,
        -- worldScale = item.worldScale,
        initialised = item:isInitialised(),
        -- stashMap = item.stashMap
    }

    if item:IsDrainable() then
        ---@cast item DrainableComboItem
        ---@cast serialised Starlit.SerialisedItemDrainable
        serialised.usedDelta = item:getUsedDelta()
    end

    if item:isCustomColor() then
        serialised.customColour = {unpack(Colour.fromColor(item:getColor())), 0}
    end

    local extraItems = item:getExtraItems()
    if extraItems then
        serialised.extraItems = {}
        for i = 0, extraItems:size() - 1 do
            table.insert(serialised.extraItems, extraItems:get(i))
        end
    end

    if item:isCustomWeight() then
        serialised.customWeight = item:getActualWeight()
    end

    local visual = item:getVisual()
    if visual then
        serialised.visual = ItemVisualSerialiser.serialise(visual)
    end

    return serialised
end

---@param serialised Starlit.SerialisedItem
---@return InventoryItem?
---@nodiscard
ItemSerialiser.deserialise = function(serialised)
    local item = InventoryItemFactory.CreateItem(serialised.fullType)
    if not item then
        log("Serialised item has missing type %d - this is normal if you removed mods recently. Cannot deserialise.", "warn", serialised.fullType)
        return nil
    end
    if item:getSaveType() ~= serialised.saveType then
        log("Serialised item's base script has changed Type, cannot deserialise.", "warn")
        return nil
    end

    item:setID(serialised.id)
    -- setUses doesn't do anything lol
    for i = item:getCurrentUses(), serialised.uses + 1, -1 do
        item:Use()
    end
    item:setCondition(serialised.condition)
    item:setItemCapacity(serialised.itemCapacity)
    item:copyModData(serialised.modData)
    item:setActivated(serialised.activated)
    item:setHaveBeenRepaired(serialised.haveBeenRepaired)
    if serialised.name then
        item:setName(serialised.name)
    end
    item:setCustomName(serialised.customName)
    item:setKeyId(serialised.keyId)
    item:setTaintedWater(serialised.taintedWater)
    item:setRemoteControlID(serialised.remoteControlId)
    item:setRemoteRange(serialised.remoteRange)
    item:setColorRed(serialised.colour[1])
    item:setColorGreen(serialised.colour[2])
    item:setColorBlue(serialised.colour[3])
    item:setWorker(serialised.worker)
    item:setWetCooldown(serialised.wetCooldown)
    item:setFavorite(serialised.favourite)
    item:setInfected(serialised.infected)
    item:setCurrentAmmoCount(serialised.currentAmmoCount)
    item:setAttachedSlot(serialised.attachedSlot)
    item:setAttachedSlotType(serialised.attachedSlotType)
    item:setAttachedToModel(serialised.attachedToModel)
    item:setMaxCapacity(serialised.maxCapacity)
    if serialised.recordedMediaIndex and serialised.recordedMediaIndex > 0 then
        item:setRecordedMediaIndexInteger(serialised.recordedMediaIndex)
    end
    -- item:setWorldZRotation(serialised.worldZRotation)
    -- item:setWorldScale(serialised.worldScale)
    item:setInitialised(serialised.initialised)

    if serialised.customColour then
        item:setCustomColor(true)
        item:setColor(
            Color.new(
                unpack(serialised.customColour), 1))
    end

    if serialised.extraItems then
        for i = 1, #serialised.extraItems do
            item:addExtraItem(serialised.extraItems[i])
        end
    end

    if serialised.customWeight then
        item:setCustomWeight(true)
        item:setActualWeight(serialised.customWeight)
    end

    -- if serialised.stashMap then
    --     item:setStashMap(serialised.stashMap)
    -- end

    if serialised.visual then
        local visual = item:getVisual()
        if visual then
            ItemVisualSerialiser.deserialise(serialised.visual, visual)
        else
            log("Serialised item has a serialised visual but the item script no longer does. This can happen if an item's ClothingItem becomes invalid. Safely skipping.", "warn")
        end
    end

    item:synchWithVisual()

    return item
end

return ItemSerialiser