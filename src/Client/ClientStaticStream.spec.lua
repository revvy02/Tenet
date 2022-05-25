return function()
    local MockNetwork = require(script.Parent.Parent.Parent.MockNetwork)
    local Slick = require(script.Parent.Parent.Parent.Slick)
    local Promise = require(script.Parent.Parent.Parent.Promise)

    local ClientStaticStream = require(script.Parent.ClientStaticStream)

    describe("ClientStaticStream.new", function()
        it("should create a new ClientStaticStream instance", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new()

            local clientStaticStream = ClientStaticStream.new({
                remoteEvent = mockRemoteEvent,
            })
    
            expect(clientStaticStream).to.be.ok()
            expect(ClientStaticStream.is(clientStaticStream)).to.equal(true)
    
            clientStaticStream:destroy()
            mockRemoteEvent:destroy()
        end)
    end)

    describe("ClientStaticStream.is", function()
        it("should return true if the passed argument is a ClientStaticStream instance", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new()

            local clientStaticStream = ClientStaticStream.new({
                remoteEvent = mockRemoteEvent,
            })
    
            expect(ClientStaticStream.is(clientStaticStream)).to.equal(true)
    
            clientStaticStream:destroy()
            mockRemoteEvent:destroy()
        end)

        it("should return false if the passed argument is not a ClientStaticStream instance", function()
            expect(ClientStaticStream.is(true)).to.equal(false)
            expect(ClientStaticStream.is(false)).to.equal(false)
            expect(ClientStaticStream.is({})).to.equal(false)
            expect(ClientStaticStream.is(0)).to.equal(false)
        end)
    end)

    describe("ClientStaticStream:get", function()
        it("should return nil if no StaticStore instance exists for the passed owner yet", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new()

            local clientStaticStream = ClientStaticStream.new({
                remoteEvent = mockRemoteEvent,
            })

            expect(clientStaticStream:get("owner")).to.equal(nil)

            clientStaticStream:destroy()
            mockRemoteEvent:destroy()
        end)

        it("should get the StaticStore instance owned by the passed owner", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new()

            local clientStaticStream = ClientStaticStream.new({
                remoteEvent = mockRemoteEvent,
            })

            mockRemoteEvent:fireClient(nil, "stream", "owner")

            expect(clientStaticStream:get("owner")).to.be.ok()
            expect(Slick.Store.is(clientStaticStream:get("owner"))).to.equal(true)

            clientStaticStream:destroy()
            mockRemoteEvent:destroy()
        end)
    end)

    describe("ClientStaticStream:streamedAsync", function()
        it("should return a promise that resolves when a store with the passed owner is streamed in", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new()

            local clientStaticStream = ClientStaticStream.new({
                remoteEvent = mockRemoteEvent,
            })
            
            local promise = clientStaticStream:streamedAsync("owner")

            expect(Promise.is(promise)).to.equal(true)
            expect(promise:getStatus()).to.equal("Started")

            mockRemoteEvent:fireClient(nil, "stream", "owner")

            expect(promise:getStatus()).to.equal("Resolved")
            expect(clientStaticStream:get("owner")).to.be.ok()

            clientStaticStream:destroy()
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