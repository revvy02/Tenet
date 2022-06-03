local MockNetwork = require(script.Parent.Parent.Parent.MockNetwork)
local Promise = require(script.Parent.Parent.Parent.Promise)

local ClientSignal = require(script.Parent.ClientSignal)
local ServerSignal = require(script.Parent.Parent.Server.ServerSignal)

return function()
    describe("ClientSignal.new", function()
        it("should create a new ClientSignal", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")

            local clientSignal = ClientSignal.new({
                remoteEvent = mockRemoteEvent,
            })
            
            expect(clientSignal).to.be.a("table")
            expect(getmetatable(clientSignal)).to.equal(ClientSignal)
            
            clientSignal:destroy()
            mockRemoteEvent:destroy()
        end)
    end)

    describe("ClientSignal:fireServer", function()
        it("should fire the server with the args", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")

            local serverSignal = ServerSignal.new({
                remoteEvent = mockRemoteEvent,
            })

            local clientSignal = ClientSignal.new({
                remoteEvent = mockRemoteEvent,
            })

            local count = 0

            serverSignal:connect(function(client, num)
                count += num
            end)

            clientSignal:fireServer(1)
            clientSignal:fireServer(2)
            clientSignal:fireServer(3)

            expect(count).to.equal(6)

            clientSignal:destroy()
            serverSignal:destroy()
            mockRemoteEvent:destroy()
        end)

        it("should queue args on server until an activating connection is made", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")

            local serverSignal = ServerSignal.new({
                remoteEvent = mockRemoteEvent,
            })

            local clientSignal = ClientSignal.new({
                remoteEvent = mockRemoteEvent,
            })

            local count = 0

            clientSignal:fireServer(1)
            clientSignal:fireServer(2)
            clientSignal:fireServer(3)

            serverSignal:connect(function(client, num)
                count += num
            end)
            
            expect(count).to.equal(6)

            clientSignal:destroy()
            serverSignal:destroy()
            mockRemoteEvent:destroy()
        end)
    end)

    describe("ClientSignal:flush", function()
        it("should prevent flushed args from being processed by an activating connection", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")

            local serverSignal = ServerSignal.new({
                remoteEvent = mockRemoteEvent,
            })

            local clientSignal = ClientSignal.new({
                remoteEvent = mockRemoteEvent,
            })

            local count = 0
            
            serverSignal:fireClient("user", 1)
            serverSignal:fireClient("user", 2)
            
            clientSignal:flush()

            serverSignal:fireClient("user", 4)
            serverSignal:fireClient("user", 3)

            clientSignal:connect(function(num)
                count += num
            end)

            expect(count).to.equal(7)

            clientSignal:destroy()
            serverSignal:destroy()
            mockRemoteEvent:destroy()
        end)
    end)

    describe("ClientSignal:connect", function()
        it("should process queued args when an activating conection is made", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")

            local serverSignal = ServerSignal.new({
                remoteEvent = mockRemoteEvent,
            })

            local clientSignal = ClientSignal.new({
                remoteEvent = mockRemoteEvent,
            })
            
            local count = 0

            serverSignal:fireClient("user", 1)
            serverSignal:fireClient("user", 2)
            serverSignal:fireClient("user", 3)

            clientSignal:connect(function(num)
                count += num
            end)
            
            expect(count).to.equal(6)

            clientSignal:destroy()
            serverSignal:destroy()
            mockRemoteEvent:destroy()
        end)

        it("should return a connection that works properly", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")

            local serverSignal = ServerSignal.new({
                remoteEvent = mockRemoteEvent,
            })

            local clientSignal = ClientSignal.new({
                remoteEvent = mockRemoteEvent,
            })

            local count0, count1 = 0, 0

            local connection0 = clientSignal:connect(function(num)
                count0 += num
            end)

            local connection1 = clientSignal:connect(function(num)
                count1 += num
            end)

            serverSignal:fireClient("user", 1)
            serverSignal:fireClient("user", 2)

            connection0:disconnect()

            serverSignal:fireClient("user", 3)

            expect(count0).to.equal(3)
            expect(count1).to.equal(6)

            connection1:disconnect()

            serverSignal:fireClient("user", 4)

            expect(count0).to.equal(3)
            expect(count1).to.equal(6)

            local connection2 = clientSignal:connect(function(num)
                count1 += num
            end)

            expect(count1).to.equal(10)

            connection2:disconnect()

            clientSignal:destroy()
            serverSignal:destroy()
            mockRemoteEvent:destroy()
        end)
    end)

    describe("ClientSignal:promise", function()
        it("should return a promise that resolves properly if args are queued", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")

            local serverSignal = ServerSignal.new({
                remoteEvent = mockRemoteEvent,
            })

            local clientSignal = ClientSignal.new({
                remoteEvent = mockRemoteEvent,
            })

            serverSignal:fireClient("user", 1)
            serverSignal:fireClient("user", 2)

            local promise0 = clientSignal:promise()
            local promise1 = clientSignal:promise()
            local promise2 = clientSignal:promise()

            expect(promise0:getStatus()).to.equal(Promise.Status.Resolved)
            expect(promise0:expect()).to.equal(1)

            expect(promise1:getStatus()).to.equal(Promise.Status.Resolved)
            expect(promise1:expect()).to.equal(2)

            expect(promise2:getStatus()).to.equal(Promise.Status.Started)

            serverSignal:fireClient("user", 3)

            expect(promise2:getStatus()).to.equal(Promise.Status.Resolved)
            expect(promise2:expect()).to.equal(3)

            clientSignal:destroy()
            serverSignal:destroy()
            mockRemoteEvent:destroy()
        end)

        it("should return a promise that resolves properly if args aren't queued", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")

            local serverSignal = ServerSignal.new({
                remoteEvent = mockRemoteEvent,
            })

            local clientSignal = ClientSignal.new({
                remoteEvent = mockRemoteEvent,
            })

            local promise0 = clientSignal:promise()
            local promise1 = clientSignal:promise()

            expect(promise0:getStatus()).to.equal(Promise.Status.Started)
            expect(promise1:getStatus()).to.equal(Promise.Status.Started)

            serverSignal:fireClient("user", 1)

            local promise2 = clientSignal:promise()

            expect(promise0:getStatus()).to.equal(Promise.Status.Resolved)
            expect(promise1:getStatus()).to.equal(Promise.Status.Resolved)
            expect(promise2:getStatus()).to.equal(Promise.Status.Started)

            serverSignal:fireClient("user", 2)
            
            expect(promise2:getStatus()).to.equal(Promise.Status.Resolved)

            expect(promise0:expect()).to.equal(1)
            expect(promise1:expect()).to.equal(1)
            expect(promise2:expect()).to.equal(2)
            
            clientSignal:destroy()
            serverSignal:destroy()
            mockRemoteEvent:destroy()
        end)
    end)

    describe("ClientSignal:destroy", function()
        it("should set destroyed field to true", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new()

            local clientSignal = ClientSignal.new({
                remoteEvent = mockRemoteEvent,
            })

            clientSignal:destroy()

            expect(clientSignal.destroyed).to.equal(true)
        end)
    end)
end