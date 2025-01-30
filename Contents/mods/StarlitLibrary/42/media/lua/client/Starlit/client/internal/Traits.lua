local Traits = require("Starlit/sandbox/Traits")
local SandboxUtils = require("Starlit/sandbox/SandboxUtils")

local log = require("Starlit/debug/StarlitLog")

local traitMetatable
if Trait.class then
    ---@type Trait
    traitMetatable = __classmetatables[Trait.class].__index
else
    log("Another mod has corrupted the global environment (replaced global Trait).", "warn")
    if instanceof(Trait, "TraitFactory$Trait") then
        log("The mod that adds the trait %s is probably to blame.", "info", Trait:getType())
        traitMetatable = getmetatable(Trait).__index
        log("Workaround succeeded.", "info")
    end
end

if not traitMetatable then
    log("Unable to get trait metatable. Sandbox options affecting traits will not work. See previous messages for info.", "error")
    return
end

-- TODO: it shows in the wrong list if you change the price and then go back to a preset difficulty (who cares, low prio)
local updateTraits = function()
    local ccp = MainScreen.instance.charCreationProfession

    for trait, data in pairs(Traits.traitInfos) do
        local label = trait:getLabel()

        if data.toggleOption and not SandboxUtils.getOptionValue(data.toggleOption) then
            ccp.listboxTrait:removeItem(label)
            ccp.listboxBadTrait:removeItem(label)
            ccp.listboxTraitSelected:removeItem(label)
            data.lastCost = nil
        elseif data.costOption then
            local newCost = trait:getCost()

            local costChange = newCost - data.lastCost

            if costChange > ccp.pointToSpend then
                ccp.listboxTrait:removeItem(label)
                ccp.listboxBadTrait:removeItem(label)
                if ccp.listboxTraitSelected:removeItem(label) then
                    ccp.pointToSpend = ccp.pointToSpend + data.lastCost
                end

                local item
                if newCost > 0 then
                    item = ccp.listboxTrait:addItem(label, trait)
                else
                    item = ccp.listboxBadTrait:addItem(label, trait)
                end

                item.tooltip = trait:getDescription()
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
traitMetatable.getCost = function(self)
    local info = Traits.traitInfos[self]
    if not info or info.costOption == "" then
        return old_getCost(self)
    end

    return -SandboxUtils.getOptionValue(info.costOption)
end

---@param self Trait
---@diagnostic disable-next-line: duplicate-set-field
traitMetatable.getRightLabel = function(self)
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
---@param self Trait
---@diagnostic disable-next-line: duplicate-set-field
traitMetatable.getTexture = function(self)
    local info = Traits.traitInfos[self]
    if not info or info.toggleOption == "" then
        return old_getTexture(self)
    end
    return SandboxUtils.getOptionValue(info.toggleOption) and old_getTexture(self) or nil
end

Events.OnConnected.Add(updateTraits)
