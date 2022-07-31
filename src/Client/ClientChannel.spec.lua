local MockNetwork = require(script.Parent.Parent.Parent.MockNetwork)
local Promise = require(script.Parent.Parent.Parent.Promise)
local Cleaner = require(script.Parent.Parent.Parent.Cleaner)

local ClientChannel = require(script.Parent.ClientChannel)
local ServerChannel = require(script.Parent.Parent.Server.ServerChannel)

return function()
    describe("ClientChannel.new", function()
        it("should create a new ClientChannel instance", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

            local clientChannel = ClientChannel.new(mockRemoteEvent, mockRemoteFunction)
    
            expect(clientChannel).to.be.a("table")
            expect(getmetatable(clientChannel)).to.equal(ClientChannel)
        end)
    end)

    describe("ClientChannel:get", function()
        it("should return nil if no dynamic store exists for the owner yet", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

            local clientChannel = ClientChannel.new(mockRemoteEvent, mockRemoteFunction)

            expect(clientChannel:get("store")).to.never.be.ok()
        end)

        it("should return the store for the owner if it exists", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

            local serverChannel = ServerChannel.new(mockRemoteEvent, mockRemoteFunction)
            local clientChannel = ClientChannel.new(mockRemoteEvent, mockRemoteFunction)

            serverChannel:create("store"):subscribe("user")
            
            expect(clientChannel:get("store")).to.be.ok()
        end)
    end)

    describe("ClientChannel:destroy", function()
        it("should disconnect any connections", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

            local clientChannel = ClientChannel.new(mockRemoteEvent, mockRemoteFunction)

            local connection0 = clientChannel.subscribed:connect(function() end)
            local connection1 = clientChannel.unsubscribed:connect(function() end)

            clientChannel:destroy()

            expect(connection0.connected).to.equal(false)
            expect(connection1.connected).to.equal(false)
        end)

        it("should set the destroyed field to true", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

            local clientChannel = ClientChannel.new(mockRemoteEvent, mockRemoteFunction)

            clientChannel:destroy()

            expect(clientChannel.destroyed).to.equal(true)
        end)
    end)
end