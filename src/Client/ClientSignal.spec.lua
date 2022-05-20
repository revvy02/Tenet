return function()
    local MockNetwork = require(script.Parent.Parent.Parent.MockNetwork)

    local ClientSignal = require(script.Parent.ClientSignal)
    local ServerSignal = require(script.Parent.Parent.Server.ServerSignal)
    
    describe("ClientSignal.new", function()
        it("should create a new ClientSignal", function()
            local remoteEvent = MockNetwork.MockRemoteEvent.new()

            local networkSignal = ClientSignal.new({
                remoteEvent = remoteEvent,
            })
            
            expect(networkSignal).to.be.ok()
            expect(networkSignal.is(networkSignal)).to.equal(true)

            remoteEvent:destroy()
            networkSignal:destroy()
        end)
    end)

    describe("ClientSignal.is", function()
        it("should return true if the passed object is a ClientSignal", function()
            local remoteEvent = MockNetwork.MockRemoteEvent.new()

            local networkSignal = ClientSignal.new({
                remoteEvent = remoteEvent,
            })

            expect(ClientSignal.is(networkSignal)).to.equal(true)

            remoteEvent:destroy()
            networkSignal:destroy()
        end)

        it("should return false if the passed object is not a ClientSignal", function()
            expect(ClientSignal.is(false)).to.equal(false)
            expect(ClientSignal.is(true)).to.equal(false)
            expect(ClientSignal.is({})).to.equal(false)
        end)
    end)



    describe("ClientSignal:flushClient", function()
        it("should ignore any flushed packets when an activating connection is made", function()
            local remoteEvent = MockNetwork.MockRemoteEvent.new()
            local count = 0

            local networkSignal = ClientSignal.new({
                remoteEvent = remoteEvent,
            })
            
            remoteEvent:fireClient(1)
            remoteEvent:fireClient(2)
            remoteEvent:fireClient(3)
            
            networkSignal:flush()

            networkSignal:connect(function(num)
                count += num
            end)

            expect(count).to.equal(0)

            remoteEvent:destroy()
            networkSignal:destroy()
        end)
    end)

    describe("ClientSignal:connect", function()
        it("should handle any queued packets when an activating conection is made", function()
            local remoteEvent = MockNetwork.MockRemoteEvent.new()
            local count = 0

            local networkSignal = ClientSignal.new({
                remoteEvent = remoteEvent,
            })

            remoteEvent:fireClient(1)
            remoteEvent:fireClient(2)
            remoteEvent:fireClient(3)

            networkSignal:connect(function(num)
                count += num
            end)
            
            expect(count).to.equal(6)

            remoteEvent:destroy()
            networkSignal:destroy()
        end)
    end)




    describe("ClientSignal:fireServer", function()
        it("should fire the server with the data", function()
            local remoteEvent = MockNetwork.MockRemoteEvent.new()
            local count = 0

            remoteEvent:connect(function(num)
                count += num
            end)

            local networkSignal = ClientSignal.new({
                remoteEvent = remoteEvent,
            })

            networkSignal:fireServer(1)
            networkSignal:fireServer(2)
            networkSignal:fireServer(3)

            expect(count).to.equal(6)

            remoteEvent:destroy()
            networkSignal:destroy()
        end)

        it("should handle queued requests when an activating connection is made", function()
            local remoteEvent = MockNetwork.MockRemoteEvent.new()
            local count = 0

            local networkSignal = ClientSignal.new({
                remoteEvent = remoteEvent,
            })

            networkSignal:fireServer(1)
            networkSignal:fireServer(2)
            networkSignal:fireServer(3)

            remoteEvent:connect(function(num)
                count += num    
            end)
            
            expect(count).to.equal(6)

            remoteEvent:destroy()
            networkSignal:destroy()
        end)
    end)







    describe("ClientSignal:destroy", function()
        it("should set destroyed field to true", function()
            local remoteEvent = MockNetwork.MockRemoteEvent.new()

            local networkSignal = ClientSignal.new({
                remoteEvent = remoteEvent,
            })
            
            remoteEvent:destroy()
            networkSignal:destroy()

            expect(networkSignal.destroyed).to.equal(true)
        end)
    end)
end