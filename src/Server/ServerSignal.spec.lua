local MockNetwork = require(script.Parent.Parent.Parent.MockNetwork)
local Promise = require(script.Parent.Parent.Parent.Promise)
local Cleaner = require(script.Parent.Parent.Parent.Cleaner)

local ClientSignal = require(script.Parent.Parent.Client.ClientSignal)
local ServerSignal = require(script.Parent.ServerSignal)

local function createCountTestEnvironment(server, names)
    local cleaner = Cleaner.new()
    
    local users = {}
    local counts = {}
    local signals = {}

    for _, name in pairs(names) do
        users[name] = server:connect(name)
    end

    for name, user in pairs(users) do
        counts[name] = 0

        signals[name] = cleaner:give(ClientSignal.new({
            remoteEvent = user:getRemoteEvent("remoteEvent"),
        }))
    end

    return users, counts, signals, cleaner
end

return function()
    describe("ServerSignal.new", function()
        it("should create a new ServerSignal object", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new()

            local serverSignal = ServerSignal.new({
                remoteEvent = mockRemoteEvent,
            })

            expect(serverSignal).to.be.a("table")
            expect(getmetatable(serverSignal)).to.equal(ServerSignal)

            serverSignal:destroy()
            mockRemoteEvent:destroy()
        end)

        it("should properly handle middleware", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new()

            local dropped = false
            local message

            local function passwordMiddleware(config)
                return function(nextMiddleware, networkElement)
                    return function(player, password, ...)
                        if password == config.password then
                            return nextMiddleware(player, password, ...)
                        else
                            config.onDropped(player, ...)
                        end
                    end
                end
            end

            local serverSignal = ServerSignal.new({
                remoteEvent = mockRemoteEvent,
            }, {
                passwordMiddleware({
                    password = "1234",
                    onDropped = function()
                        dropped = true
                    end,
                })
            })

            serverSignal:connect(function(player, password, ...)
                message = ...
            end)

            mockRemoteEvent:fireServer("4321", "message")
            expect(dropped).to.equal(true)
            expect(message).to.equal(nil)

            mockRemoteEvent:fireServer("1234", "message")
            expect(message).to.equal("message")

            serverSignal:destroy()
            mockRemoteEvent:destroy()
        end)
    end)

    describe("ServerSignal:fireClient", function()
        it("should fire the client with the args", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")

            local serverSignal = ServerSignal.new({
                remoteEvent = mockRemoteEvent,
            })

            local clientSignal = ClientSignal.new({
                remoteEvent = mockRemoteEvent,
            })

            local count = 0

            clientSignal:connect(function(num)
                count += num
            end)

            serverSignal:fireClient("user", 1)
            serverSignal:fireClient("user", 2)
            serverSignal:fireClient("user", 3)

            expect(count).to.equal(6)

            clientSignal:destroy()
            serverSignal:destroy()
            mockRemoteEvent:destroy()
        end)

        it("should queue args on client until an activating connection is made", function()
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
    end)

    describe("ServerSignal:fireClients", function()
        it("should fire each client with the args", function()
            local server = MockNetwork.Server.new()

            local serverSignal = ServerSignal.new({
                remoteEvent = server:createRemoteEvent("remoteEvent"),
            })

            local users, counts, signals, cleaner = createCountTestEnvironment(server, {"user0", "user1", "user2"})

            for name, signal in pairs(signals) do
                signal:connect(function(num)
                    counts[name] += num
                end)
            end

            serverSignal:fireClients({users.user0, users.user1}, 1)
            serverSignal:fireClients({users.user1, users.user2}, 2)

            expect(counts.user0).to.equal(1)
            expect(counts.user1).to.equal(3)
            expect(counts.user2).to.equal(2)

            cleaner:destroy()
            serverSignal:destroy()
            server:destroy()
        end)

        it("should queue args on each client until an activating connection is made", function()
            local server = MockNetwork.Server.new()

            local serverSignal = ServerSignal.new({
                remoteEvent = server:createRemoteEvent("remoteEvent"),
            })

            local users, counts, signals, cleaner = createCountTestEnvironment(server, {"user0", "user1", "user2"})
            
            serverSignal:fireClients({users.user0, users.user1}, 1)
            serverSignal:fireClients({users.user1, users.user2}, 2)

            for name, signal in pairs(signals) do
                signal:connect(function(num)
                    counts[name] += num
                end)
            end

            expect(counts.user0).to.equal(1)
            expect(counts.user1).to.equal(3)
            expect(counts.user2).to.equal(2)

            cleaner:destroy()
            serverSignal:destroy()
            server:destroy()
        end)
    end)

    describe("ServerSignal:fireAllClients", function()
        it("should fire every client with the args", function()
            local server = MockNetwork.Server.new()

            local serverSignal = ServerSignal.new({
                remoteEvent = server:createRemoteEvent("remoteEvent"),
            })
    
            local users, counts, signals, cleaner = createCountTestEnvironment(server, {"user0", "user1", "user2"})
    
            for name, signal in pairs(signals) do
                signal:connect(function(num)
                    counts[name] += num
                end)
            end
    
            serverSignal:fireAllClients(1)
            serverSignal:fireAllClients(2)
    
            expect(counts.user0).to.equal(3)
            expect(counts.user1).to.equal(3)
            expect(counts.user2).to.equal(3)
    
            
            cleaner:destroy()
            serverSignal:destroy()
            server:destroy()
        end)

        it("should queue args on every client until an activating connection is made", function()
            local server = MockNetwork.Server.new()

            local serverSignal = ServerSignal.new({
                remoteEvent = server:createRemoteEvent("remoteEvent"),
            })
    
            local users, counts, signals, cleaner = createCountTestEnvironment(server, {"user0", "user1", "user2"})

            serverSignal:fireAllClients(1)
            serverSignal:fireAllClients(2)

            for name, signal in pairs(signals) do
                signal:connect(function(num)
                    counts[name] += num
                end)
            end
    
            expect(counts.user0).to.equal(3)
            expect(counts.user1).to.equal(3)
            expect(counts.user2).to.equal(3)
            
            cleaner:destroy()
            serverSignal:destroy()
            server:destroy()
        end)
    end)

    describe("ServerSignal:flush", function()
        it("should prevent flushed args from being processed by an activating connection", function()
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
            
            serverSignal:flush()

            clientSignal:fireServer(4)
            clientSignal:fireServer(3)

            serverSignal:connect(function(user, num)
                count += num
            end)

            expect(count).to.equal(7)

            clientSignal:destroy()
            serverSignal:destroy()
            mockRemoteEvent:destroy()
        end)
    end)

    describe("ServerSignal:connect", function()
        it("should process queued args when an activating conection is made", function()
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

            serverSignal:connect(function(user, num)
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

            local connection0 = serverSignal:connect(function(user, num)
                count0 += num
            end)

            local connection1 = serverSignal:connect(function(user, num)
                count1 += num
            end)

            clientSignal:fireServer(1)
            clientSignal:fireServer(2)

            connection0:disconnect()

            clientSignal:fireServer(3)

            expect(count0).to.equal(3)
            expect(count1).to.equal(6)

            connection1:disconnect()

            clientSignal:fireServer(4)

            expect(count0).to.equal(3)
            expect(count1).to.equal(6)

            local connection2 = serverSignal:connect(function(user, num)
                count1 += num
            end)

            expect(count1).to.equal(10)

            connection2:disconnect()

            clientSignal:destroy()
            serverSignal:destroy()
            mockRemoteEvent:destroy()
        end)
    end)

    describe("ServerSignal:promise", function()
        it("should return a promise that resolves properly if args are queued", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")

            local serverSignal = ServerSignal.new({
                remoteEvent = mockRemoteEvent,
            })

            local clientSignal = ClientSignal.new({
                remoteEvent = mockRemoteEvent,
            })

            clientSignal:fireServer(1)
            clientSignal:fireServer(2)

            local promise0 = serverSignal:promise()
            local promise1 = serverSignal:promise()
            local promise2 = serverSignal:promise()

            expect(promise0:getStatus()).to.equal(Promise.Status.Resolved)
            expect(select(2, promise0:expect())).to.equal(1)

            expect(promise1:getStatus()).to.equal(Promise.Status.Resolved)
            expect(select(2, promise1:expect())).to.equal(2)

            expect(promise2:getStatus()).to.equal(Promise.Status.Started)

            clientSignal:fireServer(3)

            expect(promise2:getStatus()).to.equal(Promise.Status.Resolved)
            expect(select(2, promise2:expect())).to.equal(3)

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

            local promise0 = serverSignal:promise()
            local promise1 = serverSignal:promise()

            expect(promise0:getStatus()).to.equal(Promise.Status.Started)
            expect(promise1:getStatus()).to.equal(Promise.Status.Started)

            clientSignal:fireServer(1)

            local promise2 = serverSignal:promise()

            expect(promise0:getStatus()).to.equal(Promise.Status.Resolved)
            expect(promise1:getStatus()).to.equal(Promise.Status.Resolved)
            expect(promise2:getStatus()).to.equal(Promise.Status.Started)

            clientSignal:fireServer(2)
            
            expect(promise2:getStatus()).to.equal(Promise.Status.Resolved)

            expect(select(2, promise0:expect())).to.equal(1)
            expect(select(2, promise1:expect())).to.equal(1)
            expect(select(2, promise2:expect())).to.equal(2)
            
            clientSignal:destroy()
            serverSignal:destroy()
            mockRemoteEvent:destroy()
        end)
    end)

    describe("ClientSignal:destroy", function()
        it("should set destroyed field to true", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new()

            local serverSignal = ServerSignal.new({
                remoteEvent = mockRemoteEvent,
            })

            serverSignal:destroy()

            expect(serverSignal.destroyed).to.equal(true)
        end)
    end)
end