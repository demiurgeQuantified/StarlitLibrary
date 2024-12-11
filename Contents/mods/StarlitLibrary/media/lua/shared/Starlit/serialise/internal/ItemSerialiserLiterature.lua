local ItemSerialiser = require("Starlit/serialise/internal/ItemSerialiser")

---@class Literature
---@field customPages HashMap

---@class Starlit.SerialisedItemLiterature : Starlit.SerialisedItem
---@field saveType 3
---@field numberOfPages integer
---@field alreadyReadPages integer
---@field canBeWrite boolean
---@field customPages table<integer, string>?
---@field lockedBy string?

local ItemSerialiserLiterature = {}

---@param literature Literature
---@return Starlit.SerialisedItemLiterature
---@nodiscard
ItemSerialiserLiterature.serialise = function(literature)
    local serialised = ItemSerialiser.serialise(literature)
    ---@cast serialised Starlit.SerialisedItemLiterature
    serialised.numberOfPages = literature:getNumberOfPages()
    serialised.alreadyReadPages = literature:getAlreadyReadPages()
    serialised.canBeWrite = literature:canBeWrite()

    local customPages = literature.customPages
    if customPages then
        serialised.customPages = {}
        for i = 0, customPages:size() - 1 do
            serialised.customPages[i] = customPages:get(i)
        end
    end

    serialised.lockedBy = literature:getLockedBy()

    return serialised
end

---@param serialised Starlit.SerialisedItemLiterature
---@return Literature?
---@nodiscard
ItemSerialiserLiterature.deserialise = function(serialised)
    local literature = ItemSerialiser.deserialise(serialised) --[[@as Literature?]]
    if not literature then
        return nil
    end

    literature:setNumberOfPages(serialised.numberOfPages)
    literature:setAlreadyReadPages(serialised.alreadyReadPages)
    literature:setCanBeWrite(serialised.canBeWrite)

    if serialised.customPages then
        local customPages = literature:getCustomPages()
        for i = 0, #serialised.customPages do
            customPages:put(i, serialised.customPages[i])
        end
    end

    if serialised.lockedBy then
        literature:setLockedBy(serialised.lockedBy)
    end

    return literature
end

return ItemSerialiserLiterature