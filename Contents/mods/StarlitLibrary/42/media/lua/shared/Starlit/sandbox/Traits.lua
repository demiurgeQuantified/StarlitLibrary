---@class Starlit.TraitInfo Container for information about a trait used by the library primarily to apply sandbox options.
---@field costOption string Name of the sandbox option that sets the cost of the trait. An empty string signifies no option.
---@field toggleOption string Name of the sandbox option that toggles the availability of the trait. An empty string signifies no option.
---@field lastCost integer For internal library use - do not modify.

---Module for tying properties of traits to sandbox options
local Traits = {}

---@type {[Trait] : Starlit.TraitInfo}
Traits.traitInfos = {}

---Gets or creates TraitInfo for a trait.
---@param trait Trait The trait
---@return Starlit.TraitInfo info The TraitInfo
Traits.getOrCreateInfo = function(trait)
    local traitInfo = Traits.traitInfos[trait]
    if traitInfo then
        return traitInfo
    end

    Traits.traitInfos[trait] = {
        costOption = "",
        toggleOption = "",
        lastCost = 0,
    }

    return Traits.traitInfos[trait]
end

-- ---Ties a trait's cost to a sandbox option
-- ---@param trait Trait The trait object to modify
-- ---@param option string Name of the option as in the script (not including SandboxVars.)
-- Traits.addTraitCostOption = function(trait, option)
--     ---@param self Trait
--     ---@diagnostic disable-next-line: duplicate-set-field
--     trait.getCost = function(self)
--         return -SandboxUtils.getOptionValue(option)
--     end

--     ---@param self Trait
--     ---@diagnostic disable-next-line: duplicate-set-field
--     trait.getRightLabel = function(self)
--         local cost = trait:getCost()
--         local label
--         if cost > 0 then
--             label = "-"
--         elseif cost == 0 then
--             label = ""
--         else
--             label = "+"
--         end

--         if cost < 0 then cost = cost * -1 end

--         return label..cost
--     end

--     Traits.traitInfos[trait] = Traits.traitInfos[trait] or {}
--     Traits.traitInfos[trait].costOption = option
--     Traits.traitInfos[trait].lastCost = 0
-- end

-- ---Makes a trait available only when the sandbox option is set
-- ---@param trait Trait The trait object to modify
-- ---@param option string Name of the option as in the script (not including SandboxVars.)
-- Traits.addTraitToggleOption = function(trait, option)
--     ---@param self Trait
--     ---@diagnostic disable-next-line: duplicate-set-field
--     trait.getTexture = function(self)
--         return SandboxUtils.getOptionValue(option) and Trait_getTexture(self) or nil
--     end

--     Traits.traitInfos[trait] = Traits.traitInfos[trait] or {}
--     Traits.traitInfos[trait].toggleOption = option
-- end

return Traits