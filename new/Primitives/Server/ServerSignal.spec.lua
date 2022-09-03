local MockNetwork = require(script.Parent.Parent.Parent.Parent.MockNetwork)
local Promise = require(script.Parent.Parent.Parent.Parent.Promise)

local ClientSignal = require(script.Parent.Parent.Parent.Client.Primitives.ClientSignal)
local ServerSignal = require(script.Parent.ServerSignal)

return function()
    local function mapClientSignals(id, client)
        return id, ClientSignal.new(client:getRemoteEvent("remoteEvent"))
    end

    describe("ServerSignal.new", function()
        it("should create a new ServerSignal object", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")

            local serverSignal = ServerSignal.new(mockRemoteEvent)

            expect(serverSignal).to.be.a("table")
            expect(getmetatable(serverSignal)).to.equal(ServerSignal)
        end)

        it("should properly handle inbound middleware", function()
            local server = MockNetwork.Server.new({"user1", "user2", "user3"})
            local clients = server:mapClients()

            local dropped = {}
            local messages = {}

            local function middleware(config)
                return function(nextMiddleware, _)
                    return function(player, ...)
                        if select(config.index, ...) == config.password then
                            return nextMiddleware(player, ...)
                        else
                            config.onDropped(player, ...)
                        end
                    end
                end
            end

            local serverSignal = ServerSignal.new(server:createRemoteEvent("remoteEvent"), {
                inbound = {
                    middleware({
                        index = 1,
                        password = "1234",
                        onDropped = function(player)
                            dropped[player] = 1
                        end,
                    }),
                    middleware({
                        index = 2,
                        password = "password",
                        onDropped = function(player)
                            dropped[player] = 2
                        end,
                    })
                },
            })

            local clientSignals = server:mapClients(mapClientSignals)

            serverSignal:connect(function(player, _, _, message)
                messages[player] = message
            end)
            
            clientSignals.user1:fireServer("4321", "password", "payload1")
            clientSignals.user2:fireServer("1234", "drowssap", "payload2")
            clientSignals.user3:fireServer("1234", "password", "payload3")

            expect(dropped[clients.user1]).to.equal(1)
            expect(messages[clients.user1]).to.never.be.ok()

            expect(dropped[clients.user2]).to.equal(2)
            expect(messages[clients.user2]).to.never.be.ok()

            expect(dropped[clients.user3]).to.never.be.ok()
            expect(messages[clients.user3]).to.equal("payload3")
        end)

        it("should properly handle outbound middleware", function()
            local server = MockNetwork.Server.new({"user1", "user2", "user3"})
            local clients = server:mapClients()

            local passed = {}
            local dropped = {}

            local function middleware(config)
                return function(nextMiddleware, _)
                    return function(player, ...)
                        if select(config.index, ...) == config.password then
                            return nextMiddleware(player, ...)
                        else
                            config.onDropped(player, ...)
                        end
                    end
                end
            end

            local serverSignal = ServerSignal.new(server:createRemoteEvent("remoteEvent"), {
                outbound = {
                    middleware({
                        index = 1,
                        password = "1234",
                        onDropped = function(player)
                            dropped[player] = 1
                        end,
                    }),
                    middleware({
                        index = 2,
                        password = "password",
                        onDropped = function(player)
                            dropped[player] = 2
                        end,
                    })
                },
            })

            for user, clientSignal in pairs(server:mapClients(mapClientSignals)) do
                clientSignal:connect(function()
                    passed[clients[user]] = true
                end)
            end
            
            serverSignal:fireClient(clients.user1, "4321", "password")
            serverSignal:fireClient(clients.user2, "1234", "drowssap")
            serverSignal:fireClient(clients.user3, "1234", "password")

            expect(dropped[clients.user1]).to.equal(1)
            expect(passed[clients.user1]).to.never.be.ok()

            expect(dropped[clients.user2]).to.equal(2)
            expect(passed[clients.user2]).to.never.be.ok()

            expect(dropped[clients.user3]).to.never.be.ok()
            expect(passed[clients.user3]).to.be.ok()
        end)
    end)

    describe("ServerSignal:fireClient", function()
        it("should fire the client with the args", function()
            local server = MockNetwork.Server.new({"user1", "user2"})
            local clients = server:mapClients()

            local serverSignal = ServerSignal.new(server:createRemoteEvent("remoteEvent"))
            local clientSignals = server:mapClients(mapClientSignals)

            local counts = {
                [clients.user1] = 0,
                [clients.user2] = 0,
            }

            clientSignals.user1:connect(function(num)
                counts[clients.user1] += num
            end)

            clientSignals.user2:connect(function(num)
                counts[clients.user2] += num
            end)

            serverSignal:fireClient(clients.user1, 1)
            serverSignal:fireClient(clients.user2, 2)
            serverSignal:fireClient(clients.user2, 3)

            expect(counts[clients.user1]).to.equal(1)
            expect(counts[clients.user2]).to.equal(5)
        end)

        it("should queue args on the client until an activating connection is made", function()
            local server = MockNetwork.Server.new({"user1", "user2"})
            local clients = server:mapClients()

            local serverSignal = ServerSignal.new(server:createRemoteEvent("remoteEvent"))
            local clientSignals = server:mapClients(mapClientSignals)

            local counts = {
                [clients.user1] = 0,
                [clients.user2] = 0,
            }

            serverSignal:fireClient(clients.user1, 1)
            serverSignal:fireClient(clients.user2, 2)
            serverSignal:fireClient(clients.user2, 3)

            clientSignals.user1:connect(function(num)
                counts[clients.user1] += num
            end)

            clientSignals.user2:connect(function(num)
                counts[clients.user2] += num
            end)

            expect(counts[clients.user1]).to.equal(1)
            expect(counts[clients.user2]).to.equal(5)
        end)
    end)

    describe("ServerSignal:fireClients", function()
        it("should fire each client with the args", function()
            local server = MockNetwork.Server.new({"user1", "user2", "user3"})
            local clients = server:mapClients()

            local serverSignal = ServerSignal.new(server:createRemoteEvent("remoteEvent"))
            local clientSignals = server:mapClients(mapClientSignals)

            local counts = {
                [clients.user1] = 0,
                [clients.user2] = 0,
                [clients.user3] = 0,
            }

            clientSignals.user1:connect(function(num)
                counts[clients.user1] += num
            end)

            clientSignals.user2:connect(function(num)
                counts[clients.user2] += num
            end)

            clientSignals.user3:connect(function(num)
                counts[clients.user3] += num
            end)

            serverSignal:fireClients({clients.user1, clients.user2}, 1)
            serverSignal:fireClients({clients.user2, clients.user3}, 2)

            expect(counts[clients.user1]).to.equal(1)
            expect(counts[clients.user2]).to.equal(3)
            expect(counts[clients.user3]).to.equal(2)
        end)

        it("should queue args on each client until an activating connection is made", function()
            local server = MockNetwork.Server.new({"user1", "user2", "user3"})
            local clients = server:mapClients()
            
            local serverSignal = ServerSignal.new(server:createRemoteEvent("remoteEvent"))
            local clientSignals = server:mapClients(mapClientSignals)

            local counts = {
                [clients.user1] = 0,
                [clients.user2] = 0,
                [clients.user3] = 0,
            }

            serverSignal:fireClients({clients.user1, clients.user2}, 1)
            serverSignal:fireClients({clients.user2, clients.user3}, 2)

            clientSignals.user1:connect(function(num)
                counts[clients.user1] += num
            end)

            clientSignals.user2:connect(function(num)
                counts[clients.user2] += num
            end)

            clientSignals.user3:connect(function(num)
                counts[clients.user3] += num
            end)

            expect(counts[clients.user1]).to.equal(1)
            expect(counts[clients.user2]).to.equal(3)
            expect(counts[clients.user3]).to.equal(2)
        end)
    end)

    describe("ServerSignal:flush", function()
        it("should prevent flushed args from being processed by an activating connection", function()
            local server = MockNetwork.Server.new({"user1", "user2"})
            local clients = server:mapClients()

            local serverSignal = ServerSignal.new(server:createRemoteEvent("remoteEvent"))
            local clientSignals = server:mapClients(mapClientSignals)

            local counts = {
                [clients.user1] = 0,
                [clients.user2] = 0,
            }
            
            clientSignals.user1:fireServer(1)
            clientSignals.user1:fireServer(2)
            clientSignals.user2:fireServer(3)
            clientSignals.user2:fireServer(4)

            serverSignal:flush()

            clientSignals.user1:fireServer(1)
            clientSignals.user2:fireServer(2)

            serverSignal:connect(function(user, num)
                counts[user] += num
            end)

            expect(counts[clients.user1]).to.equal(1)
            expect(counts[clients.user2]).to.equal(2)
        end)
    end)

    describe("ServerSignal:connect", function()
        it("should process queued args when an activating conection is made", function()
            local server = MockNetwork.Server.new({"user1", "user2"})
            local clients = server:mapClients()

            local serverSignal = ServerSignal.new(server:createRemoteEvent("remoteEvent"))
            local clientSignals = server:mapClients(mapClientSignals)

            local counts = {
                [clients.user1] = 0,
                [clients.user2] = 0,
            }

            clientSignals.user1:fireServer(1)
            clientSignals.user1:fireServer(2)
            clientSignals.user2:fireServer(4)

            serverSignal:connect(function(user, num)
                counts[user] += num
            end)

            expect(counts[clients.user1]).to.equal(3)
            expect(counts[clients.user2]).to.equal(4)
        end)

        it("should return a connection that works properly", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")

            local serverSignal = ServerSignal.new(mockRemoteEvent)
            local clientSignal = ClientSignal.new(mockRemoteEvent)

            local count0, count1 = 0, 0

            local connection1 = serverSignal:connect(function(_, num)
                count0 += num
            end)

            local connection2 = serverSignal:connect(function(_, num)
                count1 += num
            end)

            clientSignal:fireServer(1)
            clientSignal:fireServer(2)

            connection1:disconnect()

            clientSignal:fireServer(3)

            expect(count0).to.equal(3)
            expect(count1).to.equal(6)

            connection2:disconnect()
        end)
    end)

    describe("ServerSignal:promise", function()
        it("should return a promise that resolves properly if args are queued", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")

            local serverSignal = ServerSignal.new(mockRemoteEvent)
            local clientSignal = ClientSignal.new(mockRemoteEvent)

            clientSignal:fireServer(1)

            local promise1 = serverSignal:promise()
            local promise2 = serverSignal:promise()

            expect(promise1:getStatus()).to.equal(Promise.Status.Resolved)

            expect(select(2, promise1:expect())).to.equal(1)

            expect(promise2:getStatus()).to.equal(Promise.Status.Started)

            clientSignal:fireServer(2)

            expect(promise2:getStatus()).to.equal(Promise.Status.Resolved)
            expect(select(2, promise2:expect())).to.equal(2)
        end)

        it("should return a promise that resolves properly if args aren't queued", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")

            local serverSignal = ServerSignal.new(mockRemoteEvent)
            local clientSignal = ClientSignal.new(mockRemoteEvent)

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
        end)
    end)

    describe("ServerSignal:destroy", function()
        it("should cleanup middleware properly", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")
            local destroyed1, destroyed2, destroyed3, destroyed4 = false, false, false, false

            local function middleware(onDestroyed)
                return function(nextMiddleware, _)
                    return function(player, ...)
                        return nextMiddleware(player, ...)
                    end,
                    onDestroyed
                end
            end

            local serverSignal = ServerSignal.new(mockRemoteEvent, {
                inbound = {
                    middleware(function()
                        destroyed1 = true
                    end),
                    middleware(function()
                        destroyed2 = true
                    end),
                },
                outbound = {
                    middleware(function()
                        destroyed3 = true
                    end),
                    middleware(function()
                        destroyed4 = true
                    end),
                },
            })

            expect(destroyed1).to.equal(false)
            expect(destroyed2).to.equal(false)
            expect(destroyed3).to.equal(false)
            expect(destroyed4).to.equal(false)

            serverSignal:destroy()

            expect(destroyed1).to.equal(true)
            expect(destroyed2).to.equal(true)
            expect(destroyed3).to.equal(true)
            expect(destroyed4).to.equal(true)
        end)

        it("should disconnect any connections", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")

            local serverSignal = ServerSignal.new(mockRemoteEvent)

            local connection1 = serverSignal:connect(function() end)

            expect(connection1.connected).to.equal(true)

            serverSignal:destroy()

            expect(connection1.connected).to.equal(false)
        end)
    end)
end