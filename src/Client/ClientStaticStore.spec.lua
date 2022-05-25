return function()
    local MockNetwork = require(script.Parent.Parent.Parent.MockNetwork)
    local Slick = require(script.Parent.Parent.Parent.Slick)

    local ClientStaticStore = require(script.Parent.ClientStaticStore)
    local StaticStore = Slick.Store

    describe("ClientStaticStore.new", function()
        it("should create a new ClientStaticStore instance", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new()

            local clientStaticStore = ClientStaticStore.new({
                remoteEvent = mockRemoteEvent
            })
    
            expect(clientStaticStore).to.be.ok()
            expect(ClientStaticStore.is(clientStaticStore)).to.equal(true)

            clientStaticStore:destroy()
            mockRemoteEvent:destroy()
        end)
    end)

    describe("ClientStaticStore.is", function()
        it("should return true if passed argument is a ClientStaticStore", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new()

            local clientStaticStore = ClientStaticStore.new({
                remoteEvent = mockRemoteEvent
            })

            expect(ClientStaticStore.is(clientStaticStore)).to.equal(true)
            
            clientStaticStore:destroy()
            mockRemoteEvent:destroy()
        end)

        it("should return false if passed argument is not a ClientStaticStore", function()
            expect(ClientStaticStore.is(true)).to.equal(false)
            expect(ClientStaticStore.is(false)).to.equal(false)
            expect(ClientStaticStore.is({})).to.equal(false)
            expect(ClientStaticStore.is(0)).to.equal(false)
        end)
    end)

    describe("ClientStaticStore:getStore", function()
        it("should return a StaticStore instance", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new()

            local clientStaticStore = ClientStaticStore.new({
                remoteEvent = mockRemoteEvent
            })
                
            expect(clientStaticStore:getStore()).to.be.ok()
            expect(StaticStore.is(clientStaticStore:getStore())).to.equal(true)
    
            clientStaticStore:destroy()
            mockRemoteEvent:destroy()
        end)
    end)

    describe("ClientStaticStore:destroy", function()
        it("should destroy the internal store", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new()

            local clientStaticStore = ClientStaticStore.new({
                remoteEvent = mockRemoteEvent
            })
    
            clientStaticStore:destroy()
            mockRemoteEvent:destroy()

            expect(clientStaticStore:getStore().destroyed).to.equal(true)
        end)

        it("should set destroyed field to true", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new()

            local clientStaticStore = ClientStaticStore.new({
                remoteEvent = mockRemoteEvent
            })
    
            clientStaticStore:destroy()
            mockRemoteEvent:destroy()

            expect(clientStaticStore.destroyed).to.equal(true)
        end)
    end)
end