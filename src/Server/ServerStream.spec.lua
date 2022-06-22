local MockNetwork = require(script.Parent.Parent.Parent.MockNetwork)
local Promise = require(script.Parent.Parent.Parent.Promise)

local ClientStream = require(script.Parent.Parent.Client.ClientStream)
local ServerStream = require(script.Parent.ServerStream)

local StaticStoreServer = require(script.Parent.StaticStoreServer)
local DynamicStoreServer = require(script.Parent.DynamicStoreServer)

return function()
    describe("ServerStream.new", function()
        it("should create a new ServerStream instance", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")

            local serverStream = ServerStream.new({
                remoteEvent = mockRemoteEvent,
            })
    
            expect(serverStream).to.be.a("table")
            expect(getmetatable(serverStream)).to.equal(ServerStream)
    
            serverStream:destroy()
            mockRemoteEvent:destroy()
        end)
    end)

    describe("ServerStream:create", function()
        it("should create a new static store for the owner if dynamic=false", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")

            local serverStream = ServerStream.new({
                remoteEvent = mockRemoteEvent,
            })

            local ssServer = serverStream:create("store")

            expect(ssServer).to.be.a("table")
            expect(getmetatable(ssServer)).to.equal(StaticStoreServer)

            serverStream:destroy()
            mockRemoteEvent:destroy()
        end)

        it("should create a new dynamic store for the owner if dynamic=true", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")

            local serverStream = ServerStream.new({
                remoteEvent = mockRemoteEvent,
            }, true)

            local dsServer = serverStream:create("store")

            expect(dsServer).to.be.a("table")
            expect(getmetatable(dsServer)).to.equal(DynamicStoreServer)

            serverStream:destroy()
            mockRemoteEvent:destroy()
        end)

        it("should fire the created signal", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")

            local serverStream = ServerStream.new({
                remoteEvent = mockRemoteEvent,
            })

            local promise = serverStream.created:promise()

            expect(promise:getStatus()).to.equal(Promise.Status.Started)

            local ssServer = serverStream:create("store")

            expect(promise:getStatus()).to.equal(Promise.Status.Resolved)

            expect(select(1, promise:expect())).to.equal("store")
            expect(select(2, promise:expect())).to.equal(ssServer)

            serverStream:destroy()
            mockRemoteEvent:destroy()
        end)
    end)

    describe("ServerStream:remove", function()
        it("should fire the removed signal", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")

            local serverStream = ServerStream.new({
                remoteEvent = mockRemoteEvent,
            })

            local promise = serverStream.removed:promise()

            expect(promise:getStatus()).to.equal(Promise.Status.Started)

            serverStream:create("store")
            serverStream:remove("store")

            expect(promise:getStatus()).to.equal(Promise.Status.Resolved)

            expect(promise:expect()).to.equal("store")

            serverStream:destroy()
            mockRemoteEvent:destroy()
        end)

        it("should fire the unstreaming signal on the client", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")

            local serverStream = ServerStream.new({
                remoteEvent = mockRemoteEvent,
            })

            local clientStream = ClientStream.new({
                remoteEvent = mockRemoteEvent,
            })

            serverStream:create("store"):stream("user")

            local promise = clientStream.unstreaming:promise()
            
            expect(promise:getStatus()).to.equal(Promise.Status.Started)

            serverStream:remove("store")

            expect(promise:getStatus()).to.equal(Promise.Status.Resolved)
            expect(promise:expect()).to.equal("store")

            clientStream:destroy()
            serverStream:destroy()
            mockRemoteEvent:destroy()
        end)
    end)

    describe("ServerStream:get", function()
        it("should return nil if no store exists for the owner yet", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new()

            local serverStream = ServerStream.new({
                remoteEvent = mockRemoteEvent,
            })

            expect(serverStream:get("store")).to.never.be.ok()

            serverStream:destroy()
            mockRemoteEvent:destroy()
        end)

        it("should return the store for the owner if it exists", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")

            local serverStream = ServerStream.new({
                remoteEvent = mockRemoteEvent,
            })

            serverStream:create("store"):stream("user")
            
            expect(serverStream:get("store")).to.be.a("table")
            expect(getmetatable(serverStream:get("store"))).to.equal(DynamicStoreServer)

            serverStream:destroy()
            mockRemoteEvent:destroy()
        end)
    end)

    describe("ServerStream:createdAsync", function()
        it("should return a promise that resolves when a store with the owner is created", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")

            local serverStream = ServerStream.new({
                remoteEvent = mockRemoteEvent,
            })
            
            local promise = serverStream:createdAsync("store")

            expect(Promise.is(promise)).to.equal(true)
            expect(promise:getStatus()).to.equal(Promise.Status.Started)

            serverStream:create("store")

            expect(promise:getStatus()).to.equal(Promise.Status.Resolved)
            
            serverStream:destroy()
            mockRemoteEvent:destroy()
        end)
    end)

    describe("ServerStream:destroy", function()
        it("should disconnect any connections", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")

            local serverStream = ServerStream.new({
                remoteEvent = mockRemoteEvent,
            })

            local connection0 = serverStream.created:connect(function() end)
            local connection1 = serverStream.removed:connect(function() end)

            serverStream:destroy()
            mockRemoteEvent:destroy()

            expect(connection0.connected).to.equal(false)
            expect(connection1.connected).to.equal(false)
        end)

        it("should set the destroyed field to true", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")

            local serverStream = ServerStream.new({
                remoteEvent = mockRemoteEvent,
            })

            serverStream:destroy()
            mockRemoteEvent:destroy()

            expect(serverStream.destroyed).to.equal(true)
        end)
    end)
end