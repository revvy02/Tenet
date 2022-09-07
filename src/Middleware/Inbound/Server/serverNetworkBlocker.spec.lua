local MockNetwork = require(script.Parent.Parent.Parent.Parent.Parent.MockNetwork)
local Promise = require(script.Parent.Parent.Parent.Parent.Parent.Promise)
local t = require(script.Parent.Parent.Parent.Parent.Parent.t)

local Primitives = require(script.Parent.Parent.Parent.Parent.Primitives)
local Middleware = require(script.Parent.Parent.Parent)

return function()
    describe("serverRuntimeTypechecker", function()
        it("should not fire connections for a ServerSignal object", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")

            local clientSignal = Primitives.Client.ClientSignal.new(mockRemoteEvent)

            local serverSignal = Primitives.Server.ServerSignal.new(mockRemoteEvent, {
                inbound = {
                    Middleware.Inbound.Server.serverNetworkBlocker(),
                }
            })

            local passed

            serverSignal:connect(function()
                passed = true
            end)

            clientSignal:fireServer()
            
            expect(passed).to.never.be.ok()
        end)

        it("should reject the promise for a ClientCallback object's callServerAsync", function()
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

            local clientCallback = Primitives.Client.ClientCallback.new(mockRemoteFunction)

            local serverCallback = Primitives.Server.ServerCallback.new(mockRemoteFunction, {
                inbound = {
                    Middleware.Inbound.Server.serverNetworkBlocker(),
                }
            })

            local passed

            serverCallback:setCallback(function(_, ...)
                passed = true
            end)

            local promise = clientCallback:callServerAsync()
            
            expect(passed).to.never.be.ok()
            expect(promise:getStatus()).to.equal(Promise.Status.Rejected)
        end)

        it("should call the log function if it exists in the primitive", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")
            local message

            local clientSignal = Primitives.Client.ClientSignal.new(mockRemoteEvent)

            local serverSignal = Primitives.Server.ServerSignal.new(mockRemoteEvent, {
                log = function(...)
                    message = ...
                end,
                inbound = {
                    Middleware.Inbound.Server.serverNetworkBlocker(),
                }
            })

            local passed

            serverSignal:connect(function(_, ...)
                passed = true 
            end)

            clientSignal:fireServer(10, 1)
            
            expect(passed).to.never.be.ok()
            expect(message).to.equal("serverNetworkBlocker violation")
        end)
    end)
end
