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
        3
    }
}

]]

insulate("ZedScript module", function()
    local ZedScript = require("Starlit/ZedScript")

    it("can load zedscript chunks", function()
        local chunk = ZedScript.loadChunk(ZEDSCRIPT)

        it("can read key-value pairs", function()
            assert.are.equal(chunk.pairs["VERSION"], "1")
        end)

        it("can read blocks", function()
            local block = chunk.blocks[1]
            assert.are.equal(block.type, "option")
            assert.are.equal(block.id, "TestMod.TestOption")
            assert.are.equal(block.pairs["foo"], "bar")

            it("can read anonymous blocks", function()
                local block = block.blocks[1]
                assert.are.equal(block.type, "")
                assert.are.equal(block.id, "")
                assert.are.equal(block.pairs["a"], "b")
                assert.are.equal(block.pairs["c"], "d")
            end)

            it("can read type-only blocks", function()
                local block = block.blocks[2]
                assert.are.equal(block.type, "type")
                assert.are.equal(block.id, "")
                it("can read non-key-value elements", function()
                    assert.are.equal(block.values[1], "1")
                    assert.are.equal(block.values[2], "2")
                    assert.are.equal(block.values[3], "3")
                end)
            end)
        end)
    end)
end)
