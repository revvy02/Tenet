local MockNetwork = require(script.Parent.Parent.Parent.MockNetwork)
local Promise = require(script.Parent.Parent.Parent.Promise)
local Cleaner = require(script.Parent.Parent.Parent.Cleaner)

local ClientChannel = require(script.Parent.Parent.Client.ClientChannel)
local ServerChannel = require(script.Parent.ServerChannel)

return function()
    local function mapClientChannels(id, client)
        return id, ClientChannel.new(client:getRemoteEvent("remoteEvent"), client:getRemoteFunction("remoteFunction"))
    end

    describe("ServerChannel.new", function()
        it("should create a new ServerChannel instance", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

            local serverChannel = ServerChannel.new(mockRemoteEvent, mockRemoteFunction)

            expect(serverChannel).to.be.a("table")
            expect(getmetatable(serverChannel)).to.equal(ServerChannel)
        end)
    end)

    describe("ServerChannel:create", function()
        it("should create a new store for the owner", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

            local serverChannel = ServerChannel.new(mockRemoteEvent, mockRemoteFunction)

            local storeServer = serverChannel:create("store")

            expect(storeServer).to.be.ok()
            expect(storeServer).to.equal(serverChannel:get("store"))
        end)

        it("should fire the created signal", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

            local serverChannel = ServerChannel.new(mockRemoteEvent, mockRemoteFunction)

            local promise = serverChannel.created:promise()

            expect(promise:getStatus()).to.equal(Promise.Status.Started)

            local storeServer = serverChannel:create("store")

            expect(promise:getStatus()).to.equal(Promise.Status.Resolved)

            expect(select(1, promise:expect())).to.equal("store")
            expect(select(2, promise:expect())).to.equal(storeServer)
        end)
    end)

    describe("ServerChannel:remove", function()
        it("should fire the removed signal", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

            local serverChannel = ServerChannel.new(mockRemoteEvent, mockRemoteFunction)

            local promise = serverChannel.removed:promise()

            expect(promise:getStatus()).to.equal(Promise.Status.Started)

            serverChannel:create("store")
            serverChannel:remove("store")

            expect(promise:getStatus()).to.equal(Promise.Status.Resolved)

            expect(promise:expect()).to.equal("store")
        end)

        it("should fire the unstreaming signal on viewing clients", function()
            local server = MockNetwork.Server.new({"user1", "user2"})
            local clients = server:mapClients()

            local serverChannel = ServerChannel.new(server:createRemoteEvent("remoteEvent"), server:createRemoteFunction("remoteFunction"))
            local clientChannels = server:mapClients(mapClientChannels)

            local storeServer = serverChannel:create("store")

            storeServer:subscribe(clients.user1)
            storeServer:subscribe(clients.user2)

            local user1promise = clientChannels.user1.unsubscribed:promise()
            local user2promise = clientChannels.user2.unsubscribed:promise()

            expect(user1promise:getStatus()).to.equal(Promise.Status.Started)
            expect(user2promise:getStatus()).to.equal(Promise.Status.Started)

            serverChannel:remove("store")

            expect(user1promise:getStatus()).to.equal(Promise.Status.Resolved)
            expect(user2promise:getStatus()).to.equal(Promise.Status.Resolved)

            expect(user1promise:expect()).to.equal("store")
            expect(user2promise:expect()).to.equal("store")
        end)
    end)

    describe("ServerChannel:get", function()
        it("should return nil if no store exists for the owner yet", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

            local serverChannel = ServerChannel.new(mockRemoteEvent, mockRemoteFunction)

            expect(serverChannel:get("store")).to.never.be.ok()
        end)

        it("should return the store for the owner if it exists", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

            local serverChannel = ServerChannel.new(mockRemoteEvent, mockRemoteFunction)

            local storeServer = serverChannel:create("store")
            
            expect(storeServer).to.be.ok()
            expect(serverChannel:get("store")).to.equal(storeServer)
        end)
    end)

    describe("ServerChannel:destroy", function()
        it("should disconnect any connections", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

            local serverChannel = ServerChannel.new(mockRemoteEvent, mockRemoteFunction)

            local connection0 = serverChannel.created:connect(function() end)
            local connection1 = serverChannel.removed:connect(function() end)

            serverChannel:destroy()

            expect(connection0.connected).to.equal(false)
            expect(connection1.connected).to.equal(false)
        end)

        it("should set the destroyed field to true", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

            local serverChannel = ServerChannel.new(mockRemoteEvent, mockRemoteFunction)

            serverChannel:destroy()

            expect(serverChannel.destroyed).to.equal(true)
        end)
    end)
end