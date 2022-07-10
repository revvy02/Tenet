local MockNetwork = require(script.Parent.Parent.MockNetwork)

local stringify = require(script.Parent.stringify)

local decode = require(script.Parent.decode)
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

    describe("decode", function()
        it("should properly decode encoded data when receiving data on the client", function()
            local remoteEvent = MockNetwork.MockRemoteEvent.new("user")
            local value1, value2, value3, value4, value5, value6, value7

            remoteEvent.OnClientEvent:Connect(function(...)
                value1, value2, value3, value4, value5, value6, value7 = decode(...)
            end)

            remoteEvent:FireClient("user", encode(1, nil, true, "string", part1, {
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
            }))

            expect(value1).to.equal(1)
            expect(value2).to.equal(nil)
            expect(value3).to.equal(true)
            expect(value4).to.equal("string")
            expect(value5).to.equal(part1)
            expect(stringify(value6)).to.equal('{["key1"]: 0, ["key2"]: {["key3"]: part1, ["key4"]: {["key5"]: part2}}}')
            expect(stringify(value7)).to.equal('{["key"]: 0, [part1]: {["key"]: 1, [part1]: 2}, [part2]: {[part1]: 3, [part2]: 4}}')
        end)

        it("should properly decode encoded data when receiving data on the server", function()
            local remoteEvent = MockNetwork.MockRemoteEvent.new("user")
            local value1, value2, value3, value4, value5, value6, value7

            remoteEvent.OnServerEvent:Connect(function(client, ...)
                value1, value2, value3, value4, value5, value6, value7 = decode(...)
            end)

            remoteEvent:FireServer(encode(1, nil, true, "string", part1, {
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
            }))

            expect(value1).to.equal(1)
            expect(value2).to.equal(nil)
            expect(value3).to.equal(true)
            expect(value4).to.equal("string")
            expect(value5).to.equal(part1)
            expect(stringify(value6)).to.equal('{["key1"]: 0, ["key2"]: {["key3"]: part1, ["key4"]: {["key5"]: part2}}}')
            expect(stringify(value7)).to.equal('{["key"]: 0, [part1]: {["key"]: 1, [part1]: 2}, [part2]: {[part1]: 3, [part2]: 4}}')
        end)

        it("should return passed args if metadata is nil", function()
            local value1, value2, value3, value4, value5, value6 = decode(nil, 1, nil, true, "string", part1, {
                key1 =  0,
                key2 = {
                    key3 = part1,
                    key4 = {
                        key5 = part2,
                    }
                },
            })

            expect(value1).to.equal(1)
            expect(value2).to.equal(nil)
            expect(value3).to.equal(true)
            expect(value4).to.equal("string")
            expect(value5).to.equal(part1)
            expect(stringify(value6)).to.equal('{["key1"]: 0, ["key2"]: {["key3"]: part1, ["key4"]: {["key5"]: part2}}}')
        end)

        it("should decode encoded data properly", function()
            local value1, value2, value3, value4, value5, value6, value7 = decode(encode(1, nil, true, "string", part1, {
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
            }))

            expect(value1).to.equal(1)
            expect(value2).to.equal(nil)
            expect(value3).to.equal(true)
            expect(value4).to.equal("string")
            expect(value5).to.equal(part1)
            expect(stringify(value6)).to.equal('{["key1"]: 0, ["key2"]: {["key3"]: part1, ["key4"]: {["key5"]: part2}}}')
            expect(stringify(value7)).to.equal('{["key"]: 0, [part1]: {["key"]: 1, [part1]: 2}, [part2]: {[part1]: 3, [part2]: 4}}')
        end)
    end)
end