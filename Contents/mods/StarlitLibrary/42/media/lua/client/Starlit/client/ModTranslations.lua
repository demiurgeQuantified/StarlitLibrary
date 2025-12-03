local json = require("Starlit/internal/json")

local log = require("Starlit/debug/Logger").getLogger("StarlitLibrary] [ModTranslations")


---@class ModTranslation
---@field name string?
---@field description string?
---@field posters string[]?


---@type table<string, ModTranslation>
local modTranslations = {}


---@param table table
---@param key any
---@return string?
---@nodiscard
local function getString(table, key)
    local str = table[key]
    if type(str) == "string" then
        return str
    end

    return nil
end


---@generic T
---@param table table
---@param key any
---@param componentType? `T`
---@return T[]?
---@nodiscard
local function getList(table, key, componentType)
    local list = table[key]
    if type(list == "table") then
        if componentType then
            for i = 1, #list do
                if not type(list[i]) == componentType then
                    return nil
                end
            end
        end

        return list
    end

    return nil
end


---@readonly
local FILE_SEPARATOR = getFileSeparator()

---@readonly
local LANGUAGE = string.lower(Translator.getLanguage():name())

---@type string[]
local modDirectories = getModDirectoryTable()


for i = 1, #modDirectories do
    local modDirectory = modDirectories[i]
    local mod = getModInfo(modDirectory)
    local modId = mod:getId()

    local file = getModFileReader(
        modId,
        "modTranslations/" .. LANGUAGE .. ".json",
        false
    )
    if file then
        local totalString = ""
        while file:ready() do
            totalString = totalString .. file:readLine() .. "\n"
        end
        file:close()

        local table = json.decode(totalString)

        local posters = getList(table, "posters", "string")
        if posters then
            for j = 1, #posters do
                local posterPath = mod:getVersionDir() .. FILE_SEPARATOR .. posters[j]
                if not getTexture(posterPath) then
                    posterPath = mod:getCommonDir() .. FILE_SEPARATOR .. posters[j]
                end
                posters[j] = posterPath
            end
        end

        modTranslations[modId] = {
            name = getString(table, "name"),
            description = getString(table, "description"),
            -- ignore empty poster lists
            posters = #posters > 0 and posters or nil
        }
    end
end


---@type ChooseGameInfo.Mod
local modMetatable = __classmetatables[zombie.gameStates.ChooseGameInfo.Mod.class].__index

local oldGetName = modMetatable.getName
---@return string
function modMetatable:getName()
    local translation = modTranslations[self:getId()]
    if translation and translation.name then
        return translation.name
    end

    return oldGetName(self)
end

local oldGetDescription = modMetatable.getDescription
---@return string
function modMetatable:getDescription()
    local translation = modTranslations[self:getId()]
    if translation and translation.description then
        return translation.description
    end

    return oldGetDescription(self)
end

local oldGetPosterCount = modMetatable.getPosterCount
---@return integer
function modMetatable:getPosterCount()
    local translation = modTranslations[self:getId()]
    if translation and translation.posters then
        return #translation.posters
    end

    return oldGetPosterCount(self)
end

local oldGetPoster = modMetatable.getPoster
---@param index integer
---@return string
function modMetatable:getPoster(index)
    local translation = modTranslations[self:getId()]
    if translation and translation.posters then
        log:debug("getPoster invoked with %d, returning %s", index, translation.posters[index + 1])
        log:debug("vanilla return would have been %s", oldGetPoster(self, index))
        return translation.posters[index + 1]
    end

    return oldGetPoster(self, index)
end

local oldGetTexture = modMetatable.getTexture
---@return Texture
function modMetatable:getTexture()
    local translation = modTranslations[self:getId()]
    if translation and translation.posters then
        return getTexture(translation.posters[1]) or Texture.getWhite()
    end

    return oldGetTexture(self)
end
