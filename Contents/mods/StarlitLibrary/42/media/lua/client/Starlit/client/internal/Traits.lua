local Traits = require("Starlit/sandbox/Traits")
local SandboxUtils = require("Starlit/sandbox/SandboxUtils")


---@type CharacterTraitDefinition
local traitMetatable = __classmetatables[CharacterTraitDefinition.class].__index


--FIXME: it shows in the wrong list if you change the price and then go back to a preset difficulty (who cares, low prio)
local function updateTraits()
    assert(MainScreen.instance ~= nil)
    local ccp = MainScreen.instance.charCreationProfession

    for trait, data in pairs(Traits.traitInfos) do
        local traitDef = CharacterTraitDefinition.getCharacterTraitDefinition(trait)
        local label = traitDef:getLabel()

        if data.toggleOption ~= "" and not SandboxUtils.getOptionValue(data.toggleOption) then
            ccp.listboxTrait:removeItem(label)
            ccp.listboxBadTrait:removeItem(label)
            ccp.listboxTraitSelected:removeItem(label)
            data.lastCost = nil
        elseif data.costOption ~= "" then
            local newCost = traitDef:getCost()

            local costChange = newCost - data.lastCost

            if costChange > ccp.pointToSpend then
                ccp.listboxTrait:removeItem(label)
                ccp.listboxBadTrait:removeItem(label)
                if ccp.listboxTraitSelected:removeItem(label) then
                    ccp.pointToSpend = ccp.pointToSpend + data.lastCost
                end

                local item
                if newCost > 0 then
                    item = ccp.listboxTrait:addItem(label, traitDef)
                else
                    item = ccp.listboxBadTrait:addItem(label, traitDef)
                end

                item.tooltip = traitDef:getDescription()
            else
                ccp.pointToSpend = ccp.pointToSpend + -costChange
            end

            data.lastCost = newCost
        end
    end

    CharacterCreationMain.sort(ccp.listboxTrait.items)
    CharacterCreationMain.invertSort(ccp.listboxBadTrait.items)
    CharacterCreationMain.sort(ccp.listboxTraitSelected.items)
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
