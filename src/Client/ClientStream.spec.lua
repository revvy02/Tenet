local MockNetwork = require(script.Parent.Parent.Parent.MockNetwork)
local Promise = require(script.Parent.Parent.Parent.Promise)
local Cleaner = require(script.Parent.Parent.Parent.Cleaner)

local ClientStream = require(script.Parent.ClientStream)
local ServerStream = require(script.Parent.Parent.Server.ServerStream)

return function()
    local cleaner = Cleaner.new()
    
    afterEach(function()
        cleaner:work()
    end)

    afterAll(function()
        cleaner:destroy()
    end)

    describe("ClientStream.new", function()
        it("should create a new ClientDynamicStream instance", function()
            local mockRemoteEvent = cleaner:give(MockNetwork.MockRemoteEvent.new("user"))

            local clientStream = cleaner:give(ClientStream.new({
                remoteEvent = mockRemoteEvent,
            }))
    
            expect(clientStream).to.be.a("table")
            expect(getmetatable(clientStream)).to.equal(ClientStream)
        end)
    end)

    describe("ClientStream:get", function()
        it("should return nil if no dynamic store exists for the owner yet", function()
            local mockRemoteEvent = cleaner:give(MockNetwork.MockRemoteEvent.new())

            local serverStream = cleaner:give(ServerStream.new({
                remoteEvent = mockRemoteEvent,
            }))

            local clientStream = cleaner:give(ClientStream.new({
                remoteEvent = mockRemoteEvent,
            }))

            expect(clientStream:get("store")).to.never.be.ok()
        end)

        it("should return the store for the owner if it exists", function()
            local mockRemoteEvent = cleaner:give(MockNetwork.MockRemoteEvent.new("user"))

            local serverStream = cleaner:give(ServerStream.new({
                remoteEvent = mockRemoteEvent,
            }))

            local clientStream = cleaner:give(ClientStream.new({
                remoteEvent = mockRemoteEvent,
            }))

            serverStream:create("store"):stream("user")
            
            expect(clientStream:get("store")).to.be.ok()
        end)
    end)

    describe("ClientStream:streamedAsync", function()
        it("should return a promise that resolves when a store with the passed owner is streamed in", function()
            local mockRemoteEvent = cleaner:give(MockNetwork.MockRemoteEvent.new("user"))

            local serverStream = cleaner:give(ServerStream.new({
                remoteEvent = mockRemoteEvent,
            }))

            local clientStream = cleaner:give(ClientStream.new({
                remoteEvent = mockRemoteEvent,
            }))
            
            local promise = clientStream:streamedAsync("store")

            expect(Promise.is(promise)).to.equal(true)
            expect(promise:getStatus()).to.equal(Promise.Status.Started)

            serverStream:create("store"):stream("user")

            expect(promise:getStatus()).to.equal(Promise.Status.Resolved)
        end)
    end)

    describe("ClientStream:destroy", function()
        it("should disconnect any connections", function()
            local mockRemoteEvent = cleaner:give(MockNetwork.MockRemoteEvent.new())

            local serverStream = cleaner:give(ServerStream.new({
                remoteEvent = mockRemoteEvent,
            }))

            local clientStream = ClientStream.new({
                remoteEvent = mockRemoteEvent,
            })

            local connection0 = clientStream.streamed:connect(function() end)
            local connection1 = clientStream.unstreaming:connect(function() end)

            clientStream:destroy()

            expect(connection0.connected).to.equal(false)
            expect(connection1.connected).to.equal(false)
        end)

        it("should set the destroyed field to true", function()
            local mockRemoteEvent = cleaner:give(MockNetwork.MockRemoteEvent.new())

            local clientStream = ClientStream.new({
                remoteEvent = mockRemoteEvent,
            })

            clientStream:destroy()

            expect(clientStream.destroyed).to.equal(true)
        end)
    end)
end