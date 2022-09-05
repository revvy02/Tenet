local MockNetwork = require(script.Parent.Parent.Parent.Parent.Parent.MockNetwork)

return function()
    describe("clientRuntimeTypechecker", function()
        it("should error if the received type is invalid", function()
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

        end)
    end)
end
