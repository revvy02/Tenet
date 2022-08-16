local MockNetwork = require(script.Parent.Parent.Parent.MockNetwork)
local Promise = require(script.Parent.Parent.Parent.Promise)
local Cleaner = require(script.Parent.Parent.Parent.Cleaner)

local ClientBroadcast = require(script.Parent.ClientBroadcast)
local ServerBroadcast = require(script.Parent.Parent.Server.ServerBroadcast)

return function()
    describe("ClientBroadcast.new", function()
        it("should create a new ClientBroadcast instance", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

            local clientBroadcast = ClientBroadcast.new(mockRemoteEvent, mockRemoteFunction)
    
            expect(ClientBroadcast).to.be.a("table")
            expect(getmetatable(clientBroadcast)).to.equal(ClientBroadcast)
        end)
    end)

    describe("ClientBroadcast:getChannel", function()
        it("should return nil if no channel exists for the host yet", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

            local clientBroadcast = ClientBroadcast.new(mockRemoteEvent, mockRemoteFunction)

            expect(clientBroadcast:getChannel("store")).to.never.be.ok()
        end)

        it("should return the atomic channel for the host if it exists", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

            local serverBroadcast = ServerBroadcast.new(mockRemoteEvent, mockRemoteFunction)
            local clientBroadcast = ClientBroadcast.new(mockRemoteEvent, mockRemoteFunction)

            serverBroadcast:createAtomicChannel("store"):subscribe("user")
            
            expect(clientBroadcast:getChannel("store")).to.be.ok()
        end)
    end)

    describe("ClientBroadcast:destroy", function()
        it("should disconnect any connections", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

            local clientBroadcast = ClientBroadcast.new(mockRemoteEvent, mockRemoteFunction)

            local connection0 = clientBroadcast.subscribed:connect(function() end)
            local connection1 = clientBroadcast.unsubscribed:connect(function() end)

            clientBroadcast:destroy()

            expect(connection0.connected).to.equal(false)
            expect(connection1.connected).to.equal(false)
        end)
    end)
end