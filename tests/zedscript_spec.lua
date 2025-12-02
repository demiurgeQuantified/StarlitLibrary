local ZEDSCRIPT = [[
VERSION = 1,

option TestMod.TestOption {
    foo = bar,
    {
        a = b,
        c = d,
    }
    type {
        1,
        2,
        3,
    }
}

]]

insulate("ZedScript module", function()
    -- http://lua-users.org/lists/lua-l/2009-12/msg00904.html
    function string.trim(s)
        local from = s:find("%S")
        return from and s:match(".*%S", from) or ""
    end

    local ZedScript = require("Starlit/ZedScript")

    describe("can load zedscript chunks", function()
        local chunk = ZedScript.loadChunk(ZEDSCRIPT)

        describe("can read key-value pairs", function()
            assert.are.equal(chunk.pairs["VERSION"], "1")
        end)

        describe("can read blocks", function()
            local block = chunk.blocks[1]
            assert.are.equal(block.type, "option")
            assert.are.equal(block.id, "TestMod.TestOption")
            assert.are.equal(block.pairs["foo"], "bar")

            describe("can read anonymous blocks", function()
                local block = block.blocks[1]
                assert.are.equal(block.type, "")
                assert.are.equal(block.id, "")
                assert.are.equal(block.pairs["a"], "b")
                assert.are.equal(block.pairs["c"], "d")
            end)

            describe("can read type-only blocks", function()
                local block = block.blocks[2]
                assert.are.equal(block.type, "type")
                assert.are.equal(block.id, "")
                describe("can read non-key-value elements", function()
                    assert.are.equal(block.values[1], "1")
                    assert.are.equal(block.values[2], "2")
                    assert.are.equal(block.values[3], "3")
                end)
            end)
        end)
    end)
end)
