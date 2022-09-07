local MockNetwork = require(script.Parent.Parent.Parent.Parent.Parent.MockNetwork)
local Promise = require(script.Parent.Parent.Parent.Parent.Parent.Promise)
local t = require(script.Parent.Parent.Parent.Parent.Parent.t)

local Primitives = require(script.Parent.Parent.Parent.Parent.Primitives)
local Middleware = require(script.Parent.Parent.Parent)

return function()
    describe("serverRuntimeTypechecker", function()
        it("should fire connections for a ServerSignal object if the type is valid", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")

            local clientSignal = Primitives.Client.ClientSignal.new(mockRemoteEvent)

            local serverSignal = Primitives.Server.ServerSignal.new(mockRemoteEvent, {
                inbound = {
                    Middleware.Inbound.Server.serverRuntimeTypechecker(t.tuple(t.number, t. boolean)),
                }
            })

            local num, bool

            serverSignal:connect(function(_, ...)
                num, bool = ...  
            end)

            clientSignal:fireServer(10, true)

            expect(num).to.equal(10)
            expect(bool).to.equal(true)
        end)

        it("should not fire connections for a ServerSignal object if the type is invalid", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")

            local clientSignal = Primitives.Client.ClientSignal.new(mockRemoteEvent)

            local serverSignal = Primitives.Server.ServerSignal.new(mockRemoteEvent, {
                inbound = {
                    Middleware.Inbound.Server.serverRuntimeTypechecker(t.tuple(t.number, t. boolean)),
                }
            })

            local num, bool

            serverSignal:connect(function(_, ...)
                num, bool = ...  
            end)

            clientSignal:fireServer(10, 1)
            
            expect(num).to.never.be.ok()
            expect(bool).to.never.be.ok()
        end)

        it("should resolve the promise for a ClientCallback object's callServerAsync if the type is valid", function()
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

            local clientCallback = Primitives.Client.ClientCallback.new(mockRemoteFunction)

            local serverCallback = Primitives.Server.ServerCallback.new(mockRemoteFunction, {
                inbound = {
                    Middleware.Inbound.Server.serverRuntimeTypechecker(t.tuple(t.number, t. boolean)),
                }
            })

            local num, bool

            serverCallback:setCallback(function(_, ...)
                num, bool = ...  
            end)

            local promise = clientCallback:callServerAsync(10, true)
            
            expect(num).to.equal(10)
            expect(bool).to.equal(true)

            expect(promise:getStatus()).to.equal(Promise.Status.Resolved)
        end)

        it("should reject the promise for a ClientCallback object's callServerAsync if the type is invalid", function()
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

            local clientCallback = Primitives.Client.ClientCallback.new(mockRemoteFunction)

            local serverCallback = Primitives.Server.ServerCallback.new(mockRemoteFunction, {
                inbound = {
                    Middleware.Inbound.Server.serverRuntimeTypechecker(t.tuple(t.number, t. boolean)),
                }
            })

            local num, bool

            serverCallback:setCallback(function(_, ...)
                num, bool = ...  
            end)

            local promise = clientCallback:callServerAsync(10, 1)
            
            expect(num).to.never.be.ok()
            expect(bool).to.never.be.ok()

            expect(promise:getStatus()).to.equal(Promise.Status.Rejected)
        end)

        it("should call the log function if it exists in the primitive and the type is invalid", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")
            local message

            local clientSignal = Primitives.Client.ClientSignal.new(mockRemoteEvent)

            local serverSignal = Primitives.Server.ServerSignal.new(mockRemoteEvent, {
                log = function(...)
                    message = ...
                end,
                inbound = {
                    Middleware.Inbound.Server.serverRuntimeTypechecker(t.tuple(t.number, t. boolean)),
                }
            })

            local num, bool

            serverSignal:connect(function(_, ...)
                num, bool = ...  
            end)

            clientSignal:fireServer(10, 1)
            
            expect(num).to.never.be.ok()
            expect(bool).to.never.be.ok()

            expect(message).to.equal("serverRuntimeTypechecker violation")
        end)
    end)
end
