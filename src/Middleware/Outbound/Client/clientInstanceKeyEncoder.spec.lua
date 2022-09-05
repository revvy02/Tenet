local MockNetwork = require(script.Parent.Parent.Parent.Parent.Parent.MockNetwork)

local Primitives = require(script.Parent.Parent.Parent.Parent.Primitives)
local Middleware = require(script.Parent.Parent.Parent)

return function()
    describe("clientInstanceKeyEncoder", function()
        it("should properly decode tables with instance keys on ServerSignal objects", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")
            local part1 = Instance.new("Part")
            local part2 = Instance.new("Part")

            local clientSignal = Primitives.Client.ClientSignal.new(mockRemoteEvent, {
                outbound = {
                    Middleware.Outbound.Client.clientInstanceKeyEncoder(),
                },
            })

            local serverSignal = Primitives.Server.ServerSignal.new(mockRemoteEvent, {
                inbound = {
                    Middleware.Inbound.Server.serverInstanceKeyDecoder(),
                }
            })

            clientSignal:fireServer({
                [part1] = 1,
                key = "ok",
            }, {
                [part2] = 2,
            })

            local _, table1, table2 = serverSignal:promise():expect()

            expect(table1[part1]).to.equal(1)
            expect(table1.key).to.equal("ok")
            expect(table2[part2]).to.equal(2)
        end)

        it("should properly decode tables with instance keys on ServerCallback objects", function()
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")
            local part1 = Instance.new("Part")
            local part2 = Instance.new("Part")

            local clientCallback = Primitives.Client.ClientCallback.new(mockRemoteFunction, {
                outbound = {
                    Middleware.Outbound.Client.clientInstanceKeyEncoder(),
                },
            })

            local serverCallback = Primitives.Server.ServerCallback.new(mockRemoteFunction, {
                inbound = {
                    Middleware.Inbound.Server.serverInstanceKeyDecoder(),
                }
            })

            local table1, table2

            clientCallback:callServerAsync({
                [part1] = 1,
                key = "ok",
            }, {
                [part2] = 2,
            })

            serverCallback:setCallback(function(client, ...)
                table1, table2 = ...
            end)

            expect(table1[part1]).to.equal(1)
            expect(table1.key).to.equal("ok")
            expect(table2[part2]).to.equal(2)
        end)
    end)
end