---@namespace starlit.zedscript


---@class Chunk
---
---Child blocks.
---@field blocks Block[]
---
---Non-key-value values.
---@field values string[]
---
---Key-value values. Duplicate keys are lost.
---@field pairs table<string, string>


---Representation of a ZedScript block.
---@class Block : Chunk
---
---First component of the block's name. May be empty.
---@field type string
---
---Second component of the block's name. May be empty.
---@field id string


---.. versionadded:: v1.5.0
---
---Module for working with ZedScript files.
local ZedScript = {}


---Loads a ZedScript chunk.
---@param chunk string ZedScript text of the chunk.
---@return Chunk chunk Representation of the data contained in the chunk.
---@nodiscard
function ZedScript.loadChunk(chunk)
    ---@type Chunk[]
    local chunkStack = {
        {
            blocks = {},
            values = {},
            pairs = {}
        }
    }

    while true do
        local blockStart = string.find(chunk, "{")
        local blockEnd = string.find(chunk, "}")
        local comma = string.find(chunk, ",")
        
        if not blockEnd and not blockStart and not comma then
            break
        end

        if not blockEnd then
            blockEnd = string.len(chunk)
        end

        if comma and comma < blockEnd and (not blockStart or comma < blockStart) then
            local value = string.sub(chunk, 1, comma - 1)

            local equalPos = string.find(value, "=")
            if equalPos then
                ---@diagnostic disable-next-line: need-check-nil
                chunkStack[#chunkStack].pairs[
                    string.trim(string.sub(value, 1, equalPos - 1))
                ] = string.trim(string.sub(value, equalPos + 1))
            else
                ---@diagnostic disable-next-line: need-check-nil
                table.insert(chunkStack[#chunkStack].values--[[@cast -?]], string.trim(value))
            end
    
            chunk = string.sub(chunk, comma + 1)
        elseif blockEnd and (not blockStart or blockEnd < blockStart) then
            assert(#chunkStack > 1, "unexpected character: '}' while not in a block")

            chunkStack[#chunkStack] = nil

            chunk = string.sub(chunk, blockEnd + 1)
        elseif blockStart then
            local blockText = string.sub(chunk, 1, blockStart - 1)

            local _, typeEnd, type = string.find(
                blockText,
                "^%s*(%S+)"
            )

            local id
            if type then
                ---@cast typeEnd -?
                id = string.match(
                    blockText,
                    "^%s*(%S+)",
                    typeEnd + 1
                ) or ""
            else
                type = ""
                id = ""
            end

            local currentBlock = chunkStack[#chunkStack]
            ---@cast currentBlock -nil
            chunkStack[#chunkStack + 1] = {
                type = type,
                id = id,
                blocks = {},
                values = {},
                pairs = {}
            }
            table.insert(currentBlock.blocks, chunkStack[#chunkStack])
            
            chunk = string.sub(chunk, blockStart + 1)
        end
    end

    assert(#chunkStack == 1, "unexpected end of chunk: currently in a block")
    return chunkStack[1]
end


return ZedScript