local MockNetwork = require(script.Parent.Parent.Parent.MockNetwork)
local Promise = require(script.Parent.Parent.Parent.Promise)
local Cleaner = require(script.Parent.Parent.Parent.Cleaner)

local ClientStream = require(script.Parent.Parent.Client.ClientStream)
local ServerStream = require(script.Parent.ServerStream)

return function()
    local cleaner = Cleaner.new()
    
    local function mapClientStreams(id, client)
        return id, cleaner:give(ClientStream.new(client:getRemoteEvent("remoteEvent")))
    end

    afterEach(function()
        cleaner:work()
    end)

    afterAll(function()
        cleaner:destroy()
    end)

    describe("ServerStream.new", function()
        it("should create a new ServerStream instance", function()
            local mockRemoteEvent = cleaner:give(MockNetwork.MockRemoteEvent.new("user"))

            local serverStream = cleaner:give(ServerStream.new(mockRemoteEvent))
    
            expect(serverStream).to.be.a("table")
            expect(getmetatable(serverStream)).to.equal(ServerStream)
        end)
    end)

    describe("ServerStream:create", function()
        it("should create a new store for the owner", function()
            local mockRemoteEvent = cleaner:give(MockNetwork.MockRemoteEvent.new("user"))

            local serverStream = cleaner:give(ServerStream.new(mockRemoteEvent))

            local storeServer = serverStream:create("store")

            expect(storeServer).to.be.ok()
            expect(storeServer).to.equal(serverStream:get("store"))
        end)

        it("should fire the created signal", function()
            local mockRemoteEvent = cleaner:give(MockNetwork.MockRemoteEvent.new("user"))

            local serverStream = cleaner:give(ServerStream.new(mockRemoteEvent))

            local promise = serverStream.created:promise()

            expect(promise:getStatus()).to.equal(Promise.Status.Started)

            local storeServer = serverStream:create("store")

            expect(promise:getStatus()).to.equal(Promise.Status.Resolved)

            expect(select(1, promise:expect())).to.equal("store")
            expect(select(2, promise:expect())).to.equal(storeServer)
        end)
    end)

    describe("ServerStream:remove", function()
        it("should fire the removed signal", function()
            local mockRemoteEvent = cleaner:give(MockNetwork.MockRemoteEvent.new("user"))

            local serverStream = cleaner:give(ServerStream.new(mockRemoteEvent))

            local promise = serverStream.removed:promise()

            expect(promise:getStatus()).to.equal(Promise.Status.Started)

            serverStream:create("store")
            serverStream:remove("store")

            expect(promise:getStatus()).to.equal(Promise.Status.Resolved)

            expect(promise:expect()).to.equal("store")
        end)

        it("should fire the unstreaming signal on viewing clients", function()
            local server = cleaner:give(MockNetwork.Server.new({"user1", "user2"}))
            local clients = server:mapClients()

            local serverStream = cleaner:give(ServerStream.new(server:createRemoteEvent("remoteEvent")))
            local clientStreams = server:mapClients(mapClientStreams)

            local storeServer = serverStream:create("store")

            storeServer:stream(clients.user1)
            storeServer:stream(clients.user2)

            local user1promise = clientStreams.user1.unstreaming:promise()
            local user2promise = clientStreams.user2.unstreaming:promise()

            expect(user1promise:getStatus()).to.equal(Promise.Status.Started)
            expect(user2promise:getStatus()).to.equal(Promise.Status.Started)

            serverStream:remove("store")

            expect(user1promise:getStatus()).to.equal(Promise.Status.Resolved)
            expect(user2promise:getStatus()).to.equal(Promise.Status.Resolved)

            expect(user1promise:expect()).to.equal("store")
            expect(user2promise:expect()).to.equal("store")
        end)
    end)

    describe("ServerStream:get", function()
        it("should return nil if no store exists for the owner yet", function()
            local mockRemoteEvent = cleaner:give(MockNetwork.MockRemoteEvent.new("user"))

            local serverStream = cleaner:give(ServerStream.new(mockRemoteEvent))

            expect(serverStream:get("store")).to.never.be.ok()
        end)

        it("should return the store for the owner if it exists", function()
            local mockRemoteEvent = cleaner:give(MockNetwork.MockRemoteEvent.new("user"))

            local serverStream = cleaner:give(ServerStream.new(mockRemoteEvent))

            local storeServer = serverStream:create("store")
            
            expect(storeServer).to.be.ok()
            expect(serverStream:get("store")).to.equal(storeServer)
        end)
    end)

    describe("ServerStream:createdAsync", function()
        it("should return a promise that resolves when a store with the owner is created", function()
            local mockRemoteEvent = cleaner:give(MockNetwork.MockRemoteEvent.new("user"))

            local serverStream = cleaner:give(ServerStream.new(mockRemoteEvent))
            
            local promise = serverStream:createdAsync("store")

            expect(Promise.is(promise)).to.equal(true)
            expect(promise:getStatus()).to.equal(Promise.Status.Started)

            serverStream:create("store")

            expect(promise:getStatus()).to.equal(Promise.Status.Resolved)
        end)
    end)

    describe("ServerStream:destroy", function()
        it("should disconnect any connections", function()
            local mockRemoteEvent = cleaner:give(MockNetwork.MockRemoteEvent.new("user"))

            local serverStream = ServerStream.new(mockRemoteEvent)

            local connection0 = serverStream.created:connect(function() end)
            local connection1 = serverStream.removed:connect(function() end)

            serverStream:destroy()

            expect(connection0.connected).to.equal(false)
            expect(connection1.connected).to.equal(false)
        end)

        it("should set the destroyed field to true", function()
            local mockRemoteEvent = cleaner:give(MockNetwork.MockRemoteEvent.new("user"))

            local serverStream = ServerStream.new(mockRemoteEvent)

            serverStream:destroy()

            expect(serverStream.destroyed).to.equal(true)
        end)
    end)
end