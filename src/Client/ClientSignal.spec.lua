return function()
    local MockNetwork = require(script.Parent.Parent.Parent.MockNetwork)

    local ClientSignal = require(script.Parent.ClientSignal)
    
    describe("ClientSignal.new", function()
        it("should create a new ClientSignal", function()
            local remoteEvent = MockNetwork.MockRemoteEvent.new()

            local clientSignal = ClientSignal.new({
                remoteEvent = remoteEvent,
            })
            
            expect(clientSignal).to.be.ok()
            expect(clientSignal.is(clientSignal)).to.equal(true)

            remoteEvent:destroy()
            clientSignal:destroy()
        end)
    end)

    describe("ClientSignal.is", function()
        it("should return true if the passed object is a ClientSignal", function()
            local remoteEvent = MockNetwork.MockRemoteEvent.new()

            local clientSignal = ClientSignal.new({
                remoteEvent = remoteEvent,
            })

            expect(ClientSignal.is(clientSignal)).to.equal(true)

            remoteEvent:destroy()
            clientSignal:destroy()
        end)

        it("should return false if the passed object is not a ClientSignal", function()
            expect(ClientSignal.is(false)).to.equal(false)
            expect(ClientSignal.is(true)).to.equal(false)
            expect(ClientSignal.is({})).to.equal(false)
        end)
    end)



    describe("ClientSignal:flush", function()
        it("should drop flushed packets when an activating connection is made", function()
            local remoteEvent = MockNetwork.MockRemoteEvent.new("user")
            local count = 0

            local clientSignal = ClientSignal.new({
                remoteEvent = remoteEvent,
            })
            
            remoteEvent:fireClient("user", 1)
            remoteEvent:fireClient("user", 2)
            remoteEvent:fireClient("user", 3)
            
            clientSignal:flush()

            remoteEvent:fireClient("user", 4)

            clientSignal:connect(function(num)
                count += num
            end)

            expect(count).to.equal(4)

            remoteEvent:destroy()
            clientSignal:destroy()
        end)
    end)

    describe("ClientSignal:connect", function()
        it("should receive queued packets when an activating conection is made", function()
            local remoteEvent = MockNetwork.MockRemoteEvent.new("user")
            local count = 0

            local clientSignal = ClientSignal.new({
                remoteEvent = remoteEvent,
            })

            remoteEvent:fireClient("user", 1)
            remoteEvent:fireClient("user", 2)
            remoteEvent:fireClient("user", 3)

            clientSignal:connect(function(num)
                count += num
            end)
            
            expect(count).to.equal(6)

            remoteEvent:destroy()
            clientSignal:destroy()
        end)
    end)




    describe("ClientSignal:fireServer", function()
        it("should fire the server with the data", function()
            local remoteEvent = MockNetwork.MockRemoteEvent.new()
            local count = 0

            remoteEvent.OnServerEvent:connect(function(_, num)
                count += num
            end)

            local clientSignal = ClientSignal.new({
                remoteEvent = remoteEvent,
            })

            clientSignal:fireServer(1)
            clientSignal:fireServer(2)
            clientSignal:fireServer(3)

            expect(count).to.equal(6)

            remoteEvent:destroy()
            clientSignal:destroy()
        end)

        it("should queue on server until an activating connection is made", function()
            local remoteEvent = MockNetwork.MockRemoteEvent.new()
            local count = 0

            local clientSignal = ClientSignal.new({
                remoteEvent = remoteEvent,
            })

            clientSignal:fireServer(1)
            clientSignal:fireServer(2)
            clientSignal:fireServer(3)

            remoteEvent.OnServerEvent:connect(function(_, num)
                count += num
            end)
            
            expect(count).to.equal(6)

            remoteEvent:destroy()
            clientSignal:destroy()
        end)
    end)
end