local ItemSerialiser = require("Starlit/serialise/internal/ItemSerialiser")

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
-- ---@field poison boolean
---@field useForPoison integer
---@field freezingTime number
---@field frozen boolean
---@field rottenTime number
---@field compostTime number
---@field cookedInMicrowave boolean
---@field fatigueChange number
---@field enduranceChange number

local ItemSerialiserFood = {}

---@param food Food
---@return Starlit.SerialisedItemFood
---@nodiscard
ItemSerialiserFood.serialise = function(food)
    local serialised = ItemSerialiser.serialise(food)

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
    --serialised.poison = food:isPoison()
    -- can't set poison U_U i think this is only for display anyway
    serialised.useForPoison = food:getUseForPoison()
    serialised.freezingTime = food:getFreezingTime()
    serialised.frozen = food:isFrozen()
    serialised.rottenTime = food:getRottenTime()
    serialised.compostTime = food:getCompostTime()
    serialised.cookedInMicrowave = food:isCookedInMicrowave()
    serialised.fatigueChange = food:getFatigueChange()
    serialised.enduranceChange = food:getEndChange()
    -- can't set lastFrozenUpdate

    return serialised
end

---@param serialised Starlit.SerialisedItemFood
---@return Food?
---@nodiscard
ItemSerialiserFood.deserialise = function(serialised)
    local food = ItemSerialiser.deserialise(serialised) --[[@as Food?]]
    if not food then
        return nil
    end

    food:setAge(serialised.age)
    food:setLastAged(serialised.lastAged)
    food:setCalories(serialised.calories)
    food:setProteins(serialised.proteins)
    food:setLipids(serialised.lipids)
    food:setCarbohydrates(serialised.carbohydrates)
    food:setHungChange(serialised.hungerChange)
    food:setBaseHunger(serialised.baseHunger)
    food:setUnhappyChange(serialised.unhappyChange)
    food:setBoredomChange(serialised.boredomChange)
    food:setThirstChange(serialised.thirstChange)
    food:setHeat(serialised.heat)
    food:setLastCookMinute(serialised.lastCookMinute)
    food:setCookingTime(serialised.cookingTime)
    food:setCooked(serialised.cooked)
    food:setBurnt(serialised.burnt)
    food:setIsCookable(serialised.isCookable)
    food:setbDangerousUncooked(serialised.dangerousUncooked)
    food:setPoisonDetectionLevel(serialised.poisonDetectionLevel)

    if serialised.spices then
        -- TODO: this should definitely be a util
        local spices = ArrayList.new(#serialised.spices)
        for i = 1, #serialised.spices do
            spices:add(serialised.spices[i])
        end
        food:setSpices(spices)
    end

    food:setPoisonPower(serialised.poisonPower)
    food:setChef(serialised.chef)
    food:setOffAge(serialised.offAge)
    food:setOffAgeMax(serialised.offageMax)
    food:setPainReduction(serialised.painReduction)
    food:setFluReduction(serialised.fluReduction)
    food:setReduceFoodSickness(serialised.reduceFoodSickness)
    food:setUseForPoison(serialised.useForPoison)
    food:setFreezingTime(serialised.freezingTime)
    food:setFrozen(serialised.frozen)
    food:setRottenTime(serialised.rottenTime)
    food:setCompostTime(serialised.compostTime)
    food:setCookedInMicrowave(serialised.cookedInMicrowave)
    food:setFatigueChange(serialised.fatigueChange)
    food:setEnduranceChange(serialised.enduranceChange)

    return food
end

return ItemSerialiserFood