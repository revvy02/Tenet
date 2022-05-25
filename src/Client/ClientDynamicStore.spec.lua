return function()
    local MockNetwork = require(script.Parent.Parent.Parent.MockNetwork)

    local ClientDynamicStore = require(script.Parent.ClientDynamicStore)
    local DynamicStore = require(script.Parent.DynamicStore)

    describe("ClientDynamicStore.new", function()
        it("should create a new ClientDynamicStore instance", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new()

            local clientDynamicStore = ClientDynamicStore.new({
                remoteEvent = mockRemoteEvent
            })
    
            expect(clientDynamicStore).to.be.ok()
            expect(ClientDynamicStore.is(clientDynamicStore)).to.equal(true)

            clientDynamicStore:destroy()
            mockRemoteEvent:destroy()
        end)
    end)

    describe("ClientDynamicStore.is", function()
        it("should return true if passed argument is a ClientDynamicStore", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new()

            local clientDynamicStore = ClientDynamicStore.new({
                remoteEvent = mockRemoteEvent
            })

            expect(ClientDynamicStore.is(clientDynamicStore)).to.equal(true)
            
            clientDynamicStore:destroy()
            mockRemoteEvent:destroy()
        end)

        it("should return false if passed argument is not a ClientDynamicStore", function()
            expect(ClientDynamicStore.is(true)).to.equal(false)
            expect(ClientDynamicStore.is(false)).to.equal(false)
            expect(ClientDynamicStore.is({})).to.equal(false)
            expect(ClientDynamicStore.is(0)).to.equal(false)
        end)
    end)

    describe("ClientDynamicStore:getStore", function()
        it("should return a DynamicStore instance", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new()

            local clientDynamicStore = ClientDynamicStore.new({
                remoteEvent = mockRemoteEvent
            })
                
            expect(clientDynamicStore:getStore()).to.be.ok()
            expect(DynamicStore.is(clientDynamicStore:getStore())).to.equal(true)
    
            clientDynamicStore:destroy()
            mockRemoteEvent:destroy()
        end)
    end)

    describe("ClientDynamicStore:destroy", function()
        it("should destroy the internal store", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new()

            local clientDynamicStore = ClientDynamicStore.new({
                remoteEvent = mockRemoteEvent
            })
    
            clientDynamicStore:destroy()
            mockRemoteEvent:destroy()

            expect(clientDynamicStore:getStore().destroyed).to.equal(true)
        end)

        it("should set destroyed field to true", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new()

            local clientDynamicStore = ClientDynamicStore.new({
                remoteEvent = mockRemoteEvent
            })
    
            clientDynamicStore:destroy()
            mockRemoteEvent:destroy()

            expect(clientDynamicStore.destroyed).to.equal(true)
        end)
    end)
end