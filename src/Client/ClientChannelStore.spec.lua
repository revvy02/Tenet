return function()
    local MockNetwork = require(script.Parent.Parent.Parent.MockNetwork)

    local ClientChannelStore = require(script.Parent.ClientChannelStore)
    local ServerChannelStore = require(script.Parent.Parent.Server.ServerChannelStore)

    local function createWithDependencies()
        local mockRemoteEvent = MockNetwork.MockRemoteEvent.new()
        local mockRemoteFunction = MockNetwork.MockRemoteFunction.new()

        local clientChannelStore = ClientChannelStore.new({
            remoteEvent = mockRemoteEvent,
            remoteFunction = mockRemoteFunction,
        })

        return clientChannelStore, function()
            clientChannelStore:destroy()
            mockRemoteEvent:destroy()
            mockRemoteFunction:destroy()
        end, mockRemoteEvent, mockRemoteFunction
    end

    local function createServer()
        local server = MockNetwork.Server.new({"Player0"})

        server:createRemoteEvent("remoteEvent")
        server:createRemoteFunction("remoteFunction")
        
        return server, server:getClient("Player0")
    end

    describe("ClientChannelStore.new", function()
        it("should create a new ClientChannelStore object", function()
            local clientChannelStore, cleanup = createWithDependencies()

            expect(clientChannelStore).to.be.ok()
            expect(clientChannelStore.is(clientChannelStore)).to.equal(true)

            cleanup()
        end)
    end)

    describe("ClientChannelStore.is", function()
        it("should return true if passed object is a ClientChannelStore", function()
            local clientChannelStore, cleanup = createWithDependencies()

            expect(clientChannelStore.is(clientChannelStore)).to.equal(true)

            cleanup()
        end)

        it("should return false if the passed object is not a ClientChannelStore", function()
            local clientChannelStore, cleanup = createWithDependencies()

            expect(ClientChannelStore.is(false)).to.equal(false)
            expect(ClientChannelStore.is(true)).to.equal(false)
            expect(ClientChannelStore.is({})).to.equal(false)

            cleanup()
        end)
    end)



    describe("ClientChannelStore:subscribeAsync", function()
        it("should return a promise that resolves with true if subscribe attempt passes", function()
            local server = MockNetwork.Server.new()

            server:connect("Player0")

            server:createRemoteEvent("remev")
            server:createRemoteFunction("remfn")

            local clientChannelStore = ClientChannelStore.new({
                remoteEvent = session:getClient("Player0"):getRemoteEvent("remev"),
                remoteFunction = session:getClient("Player0"):getRemoteFunction("remfn"),
            })

            local

            server:destroy()
        end)
        
        it("should return a promise that resolves with false if subscribe attempt passes but it's already subscribed", function()

        end)

        it("should return a promise that rejects if subscribe attempt fails", function()

        end)
    end)

    describe("ClientChannelStore:unsubscribeAsync", function()
        it("should return a promise that resolves with true if unsubscribe attempt passes and it subscribes", function()
            
        end)

        it("should return a promise that resolves with false if unsubscribe attempt passes but it's already unsubscribed", function()

        end)

        it("should return a promise that rejects if unsubscribe attempt fails", function()

        end)
    end)




    describe("ClientChannelStore:destroy", function()
        it("should set the destroyed field to true", function()
            local clientChannelStore, mockRemoteEvent, mockRemoteFunction = createWithDependencies()

            clientChannelStore:destroy()
            mockRemoteEvent:destroy()
            mockRemoteFunction:destroy()

            expect(clientChannelStore.destroyed).to.equal(true)
        end)
    end)
end