local stringify = require(script.Parent.stringify)

local encode = require(script.Parent.encode)

return function()
    local part1, part2

    beforeAll(function()
        part1 = Instance.new("Part")
        part1.Name = "part1"
        part2 = Instance.new("Part")
        part2.Name = "part2"
    end)

    afterAll(function()
        part1:Destroy()
        part2:Destroy()
    end)

    describe("encode", function()
        it("should return nil metaData and the passed args if no tables with instance keys are passed", function()
            local metaData, value1, value2, value3, value4, value5, value6 = encode(1, nil, true, "string", part1, {
                key1 =  0,
                key2 = {
                    key3 = part1,
                    key4 = {
                        key5 = part2,
                    }
                },
            })

            expect(metaData).to.never.be.ok()
            expect(value1).to.equal(1)
            expect(value2).to.equal(nil)
            expect(value3).to.equal(true)
            expect(value4).to.equal("string")
            expect(value5).to.equal(part1)
            expect(stringify(value6)).to.equal('{["key1"]: 0, ["key2"]: {["key3"]: part1, ["key4"]: {["key5"]: part2}}}')

        end)

        it("should return correctly formatted metaData and passed args if tables with instance keys are passed", function()
            local metaData, value1, value2, value3, value4, value5, value6, value7 = encode(1, nil, true, "string", part1, {
                key1 =  0,
                key2 = {
                    key3 = part1,
                    key4 = {
                        key5 = part2,
                    }
                },
            }, {
                key =  0,
                [part1] = {
                    key = 1,
                    [part1] = 2,
                },
                [part2] = {
                    [part1] = 3,
                    [part2] = 4,
                }
            })

            expect(metaData[1]).to.never.be.ok()
            expect(value1).to.equal(1)

            expect(metaData[2]).to.never.be.ok()
            expect(value2).to.equal(nil)

            expect(metaData[3]).to.never.be.ok()
            expect(value3).to.equal(true)

            expect(metaData[4]).to.never.be.ok()
            expect(value4).to.equal("string")

            expect(metaData[5]).to.never.be.ok()
            expect(value5).to.equal(part1)
            
            expect(metaData[6]).to.never.be.ok()
            expect(stringify(value6)).to.equal('{["key1"]: 0, ["key2"]: {["key3"]: part1, ["key4"]: {["key5"]: part2}}}')

            expect(metaData[7]).to.be.ok()
            expect(stringify(value7)).to.equal('{["key"]: 0}')
            expect(stringify(metaData[7])).to.equal('{{["d"]: {{["k"]: part1, ["v"]: 2}}, ["k"]: part1, ["v"]: {["key"]: 1}}, {["d"]: {{["k"]: part1, ["v"]: 3}, {["k"]: part2, ["v"]: 4}}, ["k"]: part2, ["v"]: {}}}')
        end)

        it("should throw if you try to encode cyclic tables", function()
            local data = {
                key1 = 1,
                key2 = 2,
                [part1] = 3,
            }

            data.key3 = data

            expect(function()
                encode(10, true, data)
            end).to.throw()
        end)
    end)
end