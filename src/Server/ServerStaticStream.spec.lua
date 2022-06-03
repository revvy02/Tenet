local MockNetwork = require(script.Parent.Parent.Parent.MockNetwork)
local Slick = require(script.Parent.Parent.Parent.Slick)
local Promise = require(script.Parent.Parent.Parent.Promise)

local ClientStaticStream = require(script.Parent.Parent.Client.ClientStaticStream)
local ServerStaticStream = require(script.Parent.ServerStaticStream)

local StaticStoreServer = require(script.Parent.StaticStoreServer)

return function()
    describe("ServerStaticStream.new", function()
        it("should create a new ServerStaticStream instance", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new()

            local serverStaticStream = ServerStaticStream.new({
                remoteEvent = mockRemoteEvent,
            })
    
            expect(serverStaticStream).to.be.a("table")
            expect(getmetatable(serverStaticStream)).to.equal(ServerStaticStream)
    
            serverStaticStream:destroy()
            mockRemoteEvent:destroy()
        end)
    end)

    describe("ServerStaticStream:create", function()
        it("should create a new static store for the owner", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new()

            local serverStaticStream = ServerStaticStream.new({
                remoteEvent = mockRemoteEvent,
            })

            local staticStoreServer = serverStaticStream:create("store")

            expect(staticStoreServer).to.be.a("table")
            expect(getmetatable(staticStoreServer)).to.equal(StaticStoreServer)

            serverStaticStream:destroy()
            mockRemoteEvent:destroy()
        end)

        it("should fire the created signal", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new()

            local serverStaticStream = ServerStaticStream.new({
                remoteEvent = mockRemoteEvent,
            })

            local promise = serverStaticStream.created:promise()

            expect(promise:getStatus()).to.equal(Promise.Status.Started)

            local staticStoreServer = serverStaticStream:create("store")

            expect(promise:getStatus()).to.equal(Promise.Status.Resolved)

            expect(select(1, promise:expect())).to.equal("store")
            expect(select(2, promise:expect())).to.equal(staticStoreServer)

            serverStaticStream:destroy()
            mockRemoteEvent:destroy()
        end)
    end)

    describe("ServerStaticStream:remove", function()
        it("should fire the removed signal", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new()

            local serverStaticStream = ServerStaticStream.new({
                remoteEvent = mockRemoteEvent,
            })

            local promise = serverStaticStream.removed:promise()

            expect(promise:getStatus()).to.equal(Promise.Status.Started)

            serverStaticStream:create("store")
            serverStaticStream:remove("store")

            expect(promise:getStatus()).to.equal(Promise.Status.Resolved)

            expect(promise:expect()).to.equal("store")

            serverStaticStream:destroy()
            mockRemoteEvent:destroy()
        end)

        it("should fire the unstreaming signal on the client", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")

            local serverStaticStream = ServerStaticStream.new({
                remoteEvent = mockRemoteEvent,
            })

            local clientStaticStream = ClientStaticStream.new({
                remoteEvent = mockRemoteEvent,
            })

            serverStaticStream:create("store"):stream("user")

            local promise = clientStaticStream.unstreaming:promise()
            
            expect(promise:getStatus()).to.equal(Promise.Status.Started)

            serverStaticStream:remove("store")

            expect(promise:getStatus()).to.equal(Promise.Status.Resolved)
            expect(promise:expect()).to.equal("store")

            clientStaticStream:destroy()
            serverStaticStream:destroy()
            mockRemoteEvent:destroy()
        end)
    end)

    describe("ServerStaticStream:get", function()
        it("should return nil if no static store exists for the owner yet", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new()

            local serverStaticStream = ServerStaticStream.new({
                remoteEvent = mockRemoteEvent,
            })

            expect(serverStaticStream:get("store")).to.equal(nil)

            serverStaticStream:destroy()
            mockRemoteEvent:destroy()
        end)

        it("should get the static store for the owner if it exists", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")

            local serverStaticStream = ServerStaticStream.new({
                remoteEvent = mockRemoteEvent,
            })

            serverStaticStream:create("store")
            
            expect(serverStaticStream:get("store")).to.be.a("table")
            expect(getmetatable(serverStaticStream:get("store"))).to.equal(StaticStoreServer)

            serverStaticStream:destroy()
            mockRemoteEvent:destroy()
        end)
    end)

    describe("ServerStaticStream:createdAsync", function()
        it("should return a promise that resolves when a store with the owner is created", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")

            local serverStaticStream = ServerStaticStream.new({
                remoteEvent = mockRemoteEvent,
            })
            
            local promise = serverStaticStream:createdAsync("store")

            expect(Promise.is(promise)).to.equal(true)
            expect(promise:getStatus()).to.equal(Promise.Status.Started)
            expect(serverStaticStream:get("store")).to.equal(nil)

            serverStaticStream:create("store")

            expect(promise:getStatus()).to.equal(Promise.Status.Resolved)
            expect(serverStaticStream:get("owner")).to.be.ok()
            
            serverStaticStream:destroy()
            mockRemoteEvent:destroy()
        end)
    end)

    describe("ServerStaticStream:destroy", function()
        it("should disconnect any connections", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new()

            local serverStaticStream = ServerStaticStream.new({
                remoteEvent = mockRemoteEvent,
            }) 

            local function noop() end

            local connection0 = serverStaticStream.created:connect(noop)
            local connection1 = serverStaticStream.removed:connect(noop)

            serverStaticStream:destroy()
            mockRemoteEvent:destroy()

            expect(connection0.connected).to.equal(false)
            expect(connection1.connected).to.equal(false)
        end)

        it("should set the destroyed field to true", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new()

            local serverStaticStream = ServerStaticStream.new({
                remoteEvent = mockRemoteEvent,
            })

            serverStaticStream:destroy()
            mockRemoteEvent:destroy()

            expect(serverStaticStream.destroyed).to.equal(true)
        end)
    end)
end