local MockNetwork = require(script.Parent.Parent.Parent.MockNetwork)
local Promise = require(script.Parent.Parent.Parent.Promise)
local Cleaner = require(script.Parent.Parent.Parent.Cleaner)

local ClientSignal = require(script.Parent.ClientSignal)
local ServerSignal = require(script.Parent.Parent.Server.ServerSignal)

return function()
    local cleaner = Cleaner.new()
    
    afterEach(function()
        cleaner:work()
    end)

    afterAll(function()
        cleaner:destroy()
    end)

    describe("ClientSignal.new", function()
        it("should create a new ClientSignal", function()
            local mockRemoteEvent = cleaner:give(MockNetwork.MockRemoteEvent.new("user"))

            local clientSignal = cleaner:give(ClientSignal.new(mockRemoteEvent))
            
            expect(clientSignal).to.be.a("table")
            expect(getmetatable(clientSignal)).to.equal(ClientSignal)
        end)
    end)

    describe("ClientSignal:fireServer", function()
        it("should fire the server with the args", function()
            local mockRemoteEvent = cleaner:give(MockNetwork.MockRemoteEvent.new("user"))

            local serverSignal = cleaner:give(ServerSignal.new(mockRemoteEvent))
            local clientSignal = cleaner:give(ClientSignal.new(mockRemoteEvent))

            local count = 0

            serverSignal:connect(function(client, num)
                count += num
            end)

            clientSignal:fireServer(1)
            clientSignal:fireServer(2)
            clientSignal:fireServer(3)

            expect(count).to.equal(6)
        end)

        it("should queue args on server until an activating connection is made", function()
            local mockRemoteEvent = cleaner:give(MockNetwork.MockRemoteEvent.new("user"))

            local serverSignal = cleaner:give(ServerSignal.new(mockRemoteEvent))
            local clientSignal = cleaner:give(ClientSignal.new(mockRemoteEvent))

            local count = 0

            clientSignal:fireServer(1)
            clientSignal:fireServer(2)
            clientSignal:fireServer(3)

            cleaner:give(serverSignal:connect(function(client, num)
                count += num
            end))
            
            expect(count).to.equal(6)
        end)
    end)

    describe("ClientSignal:flush", function()
        it("should prevent flushed args from being processed by an activating connection", function()
            local mockRemoteEvent = cleaner:give(MockNetwork.MockRemoteEvent.new("user"))

            local serverSignal = cleaner:give(ServerSignal.new(mockRemoteEvent))
            local clientSignal = cleaner:give(ClientSignal.new(mockRemoteEvent))

            local count = 0
            
            serverSignal:fireClient("user", 1)
            serverSignal:fireClient("user", 2)
            
            clientSignal:flush()

            serverSignal:fireClient("user", 4)
            serverSignal:fireClient("user", 3)

            cleaner:give(clientSignal:connect(function(num)
                count += num
            end))

            expect(count).to.equal(7)
        end)
    end)

    describe("ClientSignal:connect", function()
        it("should process queued args when an activating conection is made", function()
            local mockRemoteEvent = cleaner:give(MockNetwork.MockRemoteEvent.new("user"))

            local serverSignal = cleaner:give(ServerSignal.new(mockRemoteEvent))
            local clientSignal = cleaner:give(ClientSignal.new(mockRemoteEvent))
            
            local count = 0

            serverSignal:fireClient("user", 1)
            serverSignal:fireClient("user", 2)
            serverSignal:fireClient("user", 3)

            cleaner:give(clientSignal:connect(function(num)
                count += num
            end))
            
            expect(count).to.equal(6)
        end)

        it("should return a connection that works properly", function()
            local mockRemoteEvent = cleaner:give(MockNetwork.MockRemoteEvent.new("user"))

            local serverSignal = cleaner:give(ServerSignal.new(mockRemoteEvent))
            local clientSignal = cleaner:give(ClientSignal.new(mockRemoteEvent))

            local count1, count2 = 0, 0

            local connection1 = clientSignal:connect(function(num)
                count1 += num
            end)

            local connection2 = clientSignal:connect(function(num)
                count2 += num
            end)

            serverSignal:fireClient("user", 1)
            serverSignal:fireClient("user", 2)

            connection1:disconnect()

            serverSignal:fireClient("user", 3)

            expect(count1).to.equal(3)
            expect(count2).to.equal(6)

            connection2:disconnect()

            serverSignal:fireClient("user", 4)

            expect(count1).to.equal(3)
            expect(count2).to.equal(6)
        end)
    end)

    describe("ClientSignal:promise", function()
        it("should return a promise that resolves properly if args are queued", function()
            local mockRemoteEvent = cleaner:give(MockNetwork.MockRemoteEvent.new("user"))

            local serverSignal = cleaner:give(ServerSignal.new(mockRemoteEvent))
            local clientSignal = cleaner:give(ClientSignal.new(mockRemoteEvent))

            serverSignal:fireClient("user", 1)
            serverSignal:fireClient("user", 2)

            local promise1 = clientSignal:promise()
            local promise2 = clientSignal:promise()
            local promise3 = clientSignal:promise()

            expect(promise1:getStatus()).to.equal(Promise.Status.Resolved)
            expect(promise1:expect()).to.equal(1)

            expect(promise2:getStatus()).to.equal(Promise.Status.Resolved)
            expect(promise2:expect()).to.equal(2)

            expect(promise3:getStatus()).to.equal(Promise.Status.Started)

            serverSignal:fireClient("user", 3)

            expect(promise3:getStatus()).to.equal(Promise.Status.Resolved)
            expect(promise3:expect()).to.equal(3)
        end)

        it("should return a promise that resolves properly if args aren't queued", function()
            local mockRemoteEvent = cleaner:give(MockNetwork.MockRemoteEvent.new("user"))

            local serverSignal = cleaner:give(ServerSignal.new(mockRemoteEvent))
            local clientSignal = cleaner:give(ClientSignal.new(mockRemoteEvent))

            local promise1 = clientSignal:promise()
            local promise2 = clientSignal:promise()

            expect(promise1:getStatus()).to.equal(Promise.Status.Started)
            expect(promise2:getStatus()).to.equal(Promise.Status.Started)

            serverSignal:fireClient("user", 1)

            local promise3 = clientSignal:promise()

            expect(promise1:getStatus()).to.equal(Promise.Status.Resolved)
            expect(promise2:getStatus()).to.equal(Promise.Status.Resolved)
            expect(promise3:getStatus()).to.equal(Promise.Status.Started)

            serverSignal:fireClient("user", 2)
            
            expect(promise3:getStatus()).to.equal(Promise.Status.Resolved)

            expect(promise1:expect()).to.equal(1)
            expect(promise2:expect()).to.equal(1)
            expect(promise3:expect()).to.equal(2)
        end)
    end)

    describe("ClientSignal:destroy", function()
        it("should set destroyed field to true", function()
            local mockRemoteEvent = cleaner:give(MockNetwork.MockRemoteEvent.new())

            local clientSignal = ClientSignal.new(mockRemoteEvent)

            clientSignal:destroy()

            expect(clientSignal.destroyed).to.equal(true)
        end)
    end)
end