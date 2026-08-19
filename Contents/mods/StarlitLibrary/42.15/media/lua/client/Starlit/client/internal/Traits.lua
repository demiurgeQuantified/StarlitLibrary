local Traits = require("Starlit/sandbox/Traits")
local SandboxUtils = require("Starlit/sandbox/SandboxUtils")
local StarlitLog = require("Starlit/debug/StarlitLog")


---@type CharacterTraitDefinition
local traitMetatable = __classmetatables[CharacterTraitDefinition.class].__index


---@param trait CharacterTrait
---@return boolean
---@nodiscard
local function isTraitAvailable(trait)
    local data = Traits.traitInfos[trait]
    local definition = CharacterTraitDefinition.getCharacterTraitDefinition(trait)

    if data.toggleOption ~= "" then
        local available = SandboxUtils.getOptionValue(data.toggleOption)
        if type(available) ~= "boolean" then
            StarlitLog:warn(
                "Value of trait '%s' toggle sandbox option '%s' is not a boolean",
                trait:getName(),
                data.toggleOption
            )
            available = true
        elseif not available then
            return false
        end
    end

    -- don't make traits mutually exclusive with ones you already have selected available

    local items = MainScreen.instance--[[@cast -?]].charCreationProfession.listboxTraitSelected.items
    for i = 1, #items do
        local item = items[i].item ---@as CharacterTraitDefinition
        if item:isMutuallyExclusive(definition) then
            return false
        end
    end

    return true
end


--FIXME: it shows in the wrong list if you change the price and then go back to a preset difficulty (who cares, low prio)
local function updateTraits()
    assert(MainScreen.instance ~= nil)
    local ccp = MainScreen.instance.charCreationProfession

    for trait, data in pairs(Traits.traitInfos) do
        local traitDef = CharacterTraitDefinition.getCharacterTraitDefinition(trait)
        local label = traitDef:getLabel()

        local available = isTraitAvailable(trait)
        local cost = traitDef:getCost()

        local hadTrait = ccp.listboxTraitSelected:contains(label)

        ccp.listboxTrait:removeItem(label)
        ccp.listboxBadTrait:removeItem(label)
        ccp.listboxTraitSelected:removeItem(label)
    
        if hadTrait then
            ccp.pointToSpend = ccp.pointToSpend + data.lastCost
        end

        if not available then
            data.lastCost = 0
        else
            local item

            if hadTrait then
                item = ccp.listboxTraitSelected:addItem(label, traitDef)
                ccp.pointToSpend = ccp.pointToSpend - cost
            elseif cost > 0 then
                item = ccp.listboxTrait:addItem(label, traitDef)
            else
                item = ccp.listboxBadTrait:addItem(label, traitDef)
            end

            item.tooltip = traitDef:getDescription()

            data.lastCost = cost
        end
    end

    CharacterCreationMain.sort(ccp.listboxTrait.items)
    CharacterCreationMain.invertSort(ccp.listboxBadTrait.items)
    CharacterCreationMain.sort(ccp.listboxTraitSelected.items)
end

local old_repopulate = CharacterCreationProfession.repopulateTraitLists

function CharacterCreationProfession:repopulateTraitLists()
    old_repopulate(self)
    updateTraits()
end


local old_setSandboxVars = SandboxOptionsScreen.setSandboxVars
---@diagnostic disable-next-line: duplicate-set-field
SandboxOptionsScreen.setSandboxVars = function(...)
    old_setSandboxVars(...)
    updateTraits()
end


local old_getCost = traitMetatable.getCost
function traitMetatable:getCost()
    local info = Traits.traitInfos[self:getType()]
    if not info or info.costOption == "" then
        return old_getCost(self)
    end

    return -SandboxUtils.getOptionValue(info.costOption)
end


function traitMetatable:getRightLabel()
    local cost = self:getCost()

    local label
    if cost > 0 then
        label = "-"
    elseif cost == 0 then
        label = ""
    else
        label = "+"
    end

    if cost < 0 then cost = -cost end

    return label .. cost
end


local old_getTexture = traitMetatable.getTexture
function traitMetatable:getTexture()
    local info = Traits.traitInfos[self:getType()]
    if not info or info.toggleOption == "" then
        return old_getTexture(self)
    end
    return SandboxUtils.getOptionValue(info.toggleOption) and old_getTexture(self) or nil
end


Events.OnConnected.Add(updateTraits)
