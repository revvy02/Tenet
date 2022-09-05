local MockNetwork = require(script.Parent.Parent.Parent.Parent.Parent.MockNetwork)

local Primitives = require(script.Parent.Parent.Parent.Parent.Primitives)
local Middleware = require(script.Parent.Parent.Parent)

return function()
    describe("serverInstanceKeyEncoder", function()
        it("should properly decode tables with instance keys on ClientSignal objects", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")
            local part1 = Instance.new("Part")
            local part2 = Instance.new("Part")

            local clientSignal = Primitives.Client.ClientSignal.new(mockRemoteEvent, {
                inbound = {
                    Middleware.Inbound.Client.clientInstanceKeyDecoder(),
                },
            })

            local serverSignal = Primitives.Server.ServerSignal.new(mockRemoteEvent, {
                outbound = {
                    Middleware.Outbound.Server.serverInstanceKeyEncoder(),
                }
            })

            serverSignal:fireClient("user", {
                [part1] = 1,
                key = "ok",
            }, {
                [part2] = 2,
            })

            local table1, table2 = clientSignal:promise():expect()

            expect(table1[part1]).to.equal(1)
            expect(table1.key).to.equal("ok")
            expect(table2[part2]).to.equal(2)
        end)

        it("should properly decode tables with instance keys on ClientCallback objects", function()
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")
            local part1 = Instance.new("Part")
            local part2 = Instance.new("Part")

            local clientCallback = Primitives.Client.ClientCallback.new(mockRemoteFunction, {
                inbound = {
                    Middleware.Inbound.Client.clientInstanceKeyDecoder(),
                },
            })

            local serverCallback = Primitives.Server.ServerCallback.new(mockRemoteFunction, {
                outbound = {
                    Middleware.Outbound.Server.serverInstanceKeyEncoder(),
                }
            })

            local table1, table2

            serverCallback:callClientAsync("user", {
                [part1] = 1,
                key = "ok",
            }, {
                [part2] = 2,
            })

            clientCallback:setCallback(function(...)
                table1, table2 = ...
            end)

            expect(table1[part1]).to.equal(1)
            expect(table1.key).to.equal("ok")
            expect(table2[part2]).to.equal(2)
        end)
    end)
end