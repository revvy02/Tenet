local MockNetwork = require(script.Parent.Parent.Parent.MockNetwork)
local Promise = require(script.Parent.Parent.Parent.Promise)

local ClientStaticStream = require(script.Parent.ClientStaticStream)
local ServerStaticStream = require(script.Parent.Parent.Server.ServerStaticStream)

local StaticStoreClient = require(script.Parent.StaticStoreClient)

return function()
    describe("ClientStaticStream.new", function()
        it("should create a new ClientStaticStream instance", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new()

            local clientStaticStream = ClientStaticStream.new({
                remoteEvent = mockRemoteEvent,
            })
    
            expect(clientStaticStream).to.be.a("table")
            expect(getmetatable(clientStaticStream)).to.equal(ClientStaticStream)
    
            clientStaticStream:destroy()
            mockRemoteEvent:destroy()
        end)
    end)

    describe("ClientStaticStream:get", function()
        it("should return nil if no static store exists for the owner yet", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new()

            local clientStaticStream = ClientStaticStream.new({
                remoteEvent = mockRemoteEvent,
            })

            expect(clientStaticStream:get("owner")).to.equal(nil)

            clientStaticStream:destroy()
            mockRemoteEvent:destroy()
        end)

        it("should get the static store for the owner if it exists", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")

            local clientStaticStream = ClientStaticStream.new({
                remoteEvent = mockRemoteEvent,
            })

            local serverStaticStream = ServerStaticStream.new({
                remoteEvent = mockRemoteEvent,
            })

            serverStaticStream:create("owner"):stream("user")
            
            expect(clientStaticStream:get("owner")).to.be.a("table")
            expect(getmetatable(clientStaticStream:get(""))).to.equal(StaticStoreClient)

            clientStaticStream:destroy()
            serverStaticStream:destroy()
            mockRemoteEvent:destroy()
        end)
    end)

    describe("ClientStaticStream:streamedAsync", function()
        it("should return a promise that resolves when a store with the passed owner is streamed in", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")

            local clientStaticStream = ClientStaticStream.new({
                remoteEvent = mockRemoteEvent,
            })

            local serverStaticStream = ServerStaticStream.new({
                remoteEvent = mockRemoteEvent,
            })
            
            local promise = clientStaticStream:streamedAsync("owner")

            expect(Promise.is(promise)).to.equal(true)
            expect(promise:getStatus()).to.equal(Promise.Status.Started)
            expect(clientStaticStream:get("owner")).to.equal(nil)

            serverStaticStream:create("owner"):stream("user")

            expect(promise:getStatus()).to.equal(Promise.Status.Resolved)
            expect(clientStaticStream:get("owner")).to.be.ok()

            clientStaticStream:destroy()
            serverStaticStream:destroy()
            mockRemoteEvent:destroy()
        end)
    end)

    describe("ClientStaticStream:destroy", function()
        it("should disconnect any connections", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new()

            local clientStaticStream = ClientStaticStream.new({
                remoteEvent = mockRemoteEvent,
            }) 

            local function noop() end

            local connection0 = clientStaticStream.streamed:connect(noop)
            local connection1 = clientStaticStream.unstreaming:connect(noop)

            clientStaticStream:destroy()
            mockRemoteEvent:destroy()

            expect(connection0.connected).to.equal(false)
            expect(connection1.connected).to.equal(false)
        end)

        it("should set the destroyed field to true", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new()

            local clientStaticStream = ClientStaticStream.new({
                remoteEvent = mockRemoteEvent,
            })

            clientStaticStream:destroy()
            mockRemoteEvent:destroy()

            expect(clientStaticStream.destroyed).to.equal(true)
        end)
    end)
end