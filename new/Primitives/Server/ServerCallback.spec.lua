local MockNetwork = require(script.Parent.Parent.Parent.Parent.MockNetwork)
local Promise = require(script.Parent.Parent.Parent.Parent.Promise)
local Cleaner = require(script.Parent.Parent.Parent.Parent.Cleaner)

local ServerCallback = require(script.Parent.ServerCallback)
local ClientCallback = require(script.Parent.Parent.Parent.Client.Primitives.ClientCallback)

return function()
    local function mapClientCallbacks(id, client)
        return id, ClientCallback.new(client:getRemoteFunction("remoteFunction"))
    end

    describe("ServerCallback.new", function()
        it("should create a new ServerCallback object", function()
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

            local serverCallback = ServerCallback.new(mockRemoteFunction)

            expect(serverCallback).to.be.a("table")
            expect(getmetatable(serverCallback)).to.equal(ServerCallback)
        end)

        it("should handle inbound middleware properly", function()
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

            local serverCallback = ServerCallback.new(server:createRemoteFunction("remoteFunction"), {
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

            local clientCallbacks = server:mapClients(mapClientCallbacks)

            serverCallback:setCallback(function(player, _, _, message)
                messages[player] = message
            end)

            clientCallbacks.user1:callServerAsync("4321", "password", "payload1")
            clientCallbacks.user2:callServerAsync("1234", "drowssap", "payload2")
            clientCallbacks.user3:callServerAsync("1234", "password", "payload3")

            expect(dropped[clients.user1]).to.equal(1)
            expect(messages[clients.user1]).to.never.be.ok()

            expect(dropped[clients.user2]).to.equal(2)
            expect(messages[clients.user2]).to.never.be.ok()

            expect(dropped[clients.user3]).to.never.be.ok()
            expect(messages[clients.user3]).to.equal("payload3")
        end)

        it("should handle outbound middleware properly", function()
            local server = MockNetwork.Server.new({"user1", "user2", "user3"})
            local clients = server:mapClients()

            local dropped = {}
            local passed = {}

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

            local serverCallback = ServerCallback.new(server:createRemoteFunction("remoteFunction"), {
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

            for user, clientCallback in server:mapClients(mapClientCallbacks) do
                clientCallback:setCallback(function()
                    passed[clients[user]] = true
                end)
            end

            serverCallback:callClientAsync(clients.user1, "4321", "password")
            serverCallback:callClientAsync(clients.user2, "1234", "drowssap")
            serverCallback:callClientAsync(clients.user3, "1234", "password")

            expect(dropped[clients.user1]).to.equal(1)
            expect(passed[clients.user1]).to.never.be.ok()

            expect(dropped[clients.user2]).to.equal(2)
            expect(passed[clients.user2]).to.never.be.ok()

            expect(dropped[clients.user3]).to.never.be.ok()
            expect(passed[clients.user3]).to.be.ok()
        end)
    end)

    ---

    describe("ServerCallback:setCallback", function()
        it("should resolve queued requests from the client with the response if the callback doesn't error", function()
            local server = MockNetwork.Server.new({"user1", "user2"})
            local clients = server:mapClients()

            local serverCallback = ServerCallback.new(server:createRemoteFunction("remoteFunction"))
            local clientCallbacks = server:mapClients(mapClientCallbacks)

            local counts = {
                [clients.user1] = 0,
                [clients.user2] = 0,
            }

            local user1promise1 = clientCallbacks.user1:callServerAsync(1)
            local user1promise2 = clientCallbacks.user1:callServerAsync(2)

            expect(user1promise1:getStatus()).to.equal(Promise.Status.Started)
            expect(user1promise2:getStatus()).to.equal(Promise.Status.Started)

            local user2promise1 = clientCallbacks.user2:callServerAsync(3)
            local user2promise2 = clientCallbacks.user2:callServerAsync(4)

            expect(user2promise1:getStatus()).to.equal(Promise.Status.Started)
            expect(user2promise2:getStatus()).to.equal(Promise.Status.Started)

            serverCallback:setCallback(function(client, num)
                counts[client] += num
            end)

            expect(counts[clients.user1]).to.equal(3)
            expect(counts[clients.user2]).to.equal(7)
        end)

        it("should reject queued requests from the client if the callback errors", function()
            local server = MockNetwork.Server.new({"user1", "user2"})

            local serverCallback = ServerCallback.new(server:createRemoteFunction("remoteFunction"))
            local clientCallbacks = server:mapClients(mapClientCallbacks)

            local user1promise = clientCallbacks.user1:callServerAsync("z4321")
            local user2promise = clientCallbacks.user1:callServerAsync("z1234")

            expect(user1promise:getStatus()).to.equal(Promise.Status.Started)
            expect(user2promise:getStatus()).to.equal(Promise.Status.Started)

            serverCallback:setCallback(function(_, password)
                assert(password == "z1234", "Uh oh!")

                return "Yay!"
            end)

            expect(user1promise:getStatus()).to.equal(Promise.Status.Rejected)

            expect(user2promise:getStatus()).to.equal(Promise.Status.Resolved)
            expect(user2promise:expect()).to.equal("Yay!")
        end)
    end)

    describe("ServerCallback:flush", function()
        it("should reject queued requests from the client with an error", function()
            local server = MockNetwork.Server.new({"user1", "user2"})

            local serverCallback = ServerCallback.new(server:createRemoteFunction("remoteFunction"))
            local clientCallbacks = server:mapClients(mapClientCallbacks)

            local user1promise = clientCallbacks.user1:callServerAsync()
            local user2promise = clientCallbacks.user2:callServerAsync()

            expect(user1promise:getStatus()).to.equal(Promise.Status.Started)
            expect(user2promise:getStatus()).to.equal(Promise.Status.Started)

            serverCallback:flush()

            expect(user1promise:getStatus()).to.equal(Promise.Status.Rejected)
            expect(user2promise:getStatus()).to.equal(Promise.Status.Rejected)
        end)
    end)

    describe("ServerCallback:callClientAsync", function()
        it("should return a promise that resolves with the response from the client if it doesn't error", function()
            local server = MockNetwork.Server.new({"user1", "user2"})
            local clients = server:mapClients()

            local serverCallback = ServerCallback.new(server:createRemoteFunction("remoteFunction"))
            local clientCallbacks = server:mapClients(mapClientCallbacks)

            clientCallbacks.user1:setCallback(function()
                return 1
            end)

            clientCallbacks.user2:setCallback(function()
                return 2
            end)

            local user1promise = serverCallback:callClientAsync(clients.user1)
            local user2promise = serverCallback:callClientAsync(clients.user2)

            expect(user1promise:getStatus()).to.equal(Promise.Status.Resolved)
            expect(user2promise:getStatus()).to.equal(Promise.Status.Resolved)

            expect(user1promise:expect()).to.equal(1)
            expect(user2promise:expect()).to.equal(2)
        end)

        it("should return a promise that rejects if the client errors", function()
            local server = MockNetwork.Server.new({"user1", "user2"})
            local clients = server:mapClients()

            local serverCallback = ServerCallback.new(server:createRemoteFunction("remoteFunction"))
            local clientCallbacks = server:mapClients(mapClientCallbacks)

            clientCallbacks.user1:setCallback(function()
                error("Whoops!")
            end)

            clientCallbacks.user2:setCallback(function()
                error("Whoops!")
            end)

            local user1promise = serverCallback:callClientAsync(clients.user1)
            local user2promise = serverCallback:callClientAsync(clients.user2)

            expect(user1promise:getStatus()).to.equal(Promise.Status.Rejected)
            expect(user2promise:getStatus()).to.equal(Promise.Status.Rejected)
        end)

        it("should queue request if the client callback isn't set and resolve once it is", function()
            local server = MockNetwork.Server.new({"user1", "user2"})
            local clients = server:mapClients()

            local serverCallback = ServerCallback.new(server:createRemoteFunction("remoteFunction"))
            local clientCallbacks = server:mapClients(mapClientCallbacks)

            local user1promise = serverCallback:callClientAsync(clients.user1)
            local user2promise = serverCallback:callClientAsync(clients.user2)

            expect(user1promise:getStatus()).to.equal(Promise.Status.Started)
            expect(user2promise:getStatus()).to.equal(Promise.Status.Started)

            clientCallbacks.user1:setCallback(function()
                return 1
            end)

            clientCallbacks.user2:setCallback(function()
                return 2
            end)

            expect(user1promise:getStatus()).to.equal(Promise.Status.Resolved)
            expect(user2promise:getStatus()).to.equal(Promise.Status.Resolved)

            expect(user1promise:expect()).to.equal(1)
            expect(user2promise:expect()).to.equal(2)
        end)
    end)

    describe("ServerCallback:destroy", function()
        it("should cleanup middleware properly", function()
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")
            local destroyed1, destroyed2, destroyed3, destroyed4 = false, false, false, false

            local function middleware(onDestroyed)
                return function(nextMiddleware, _)
                    return function(player, ...)
                        return nextMiddleware(player, ...)
                    end,
                    onDestroyed
                end
            end

            local serverCallback = ServerCallback.new(mockRemoteFunction , {
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

            serverCallback:destroy()

            expect(destroyed1).to.equal(true)
            expect(destroyed2).to.equal(true)
            expect(destroyed3).to.equal(true)
            expect(destroyed4).to.equal(true)
        end)

        it("should reject queued requests from the client with an error", function()
            local server = MockNetwork.Server.new({"user1", "user2"})

            local serverCallback = ServerCallback.new(server:createRemoteFunction("remoteFunction"))
            local clientCallbacks = server:mapClients(mapClientCallbacks)

            local user1promise = clientCallbacks.user1:callServerAsync()
            local user2promise = clientCallbacks.user2:callServerAsync()

            expect(user1promise:getStatus()).to.equal(Promise.Status.Started)
            expect(user2promise:getStatus()).to.equal(Promise.Status.Started)

            serverCallback:destroy()

            expect(user1promise:getStatus()).to.equal(Promise.Status.Rejected)
            expect(user2promise:getStatus()).to.equal(Promise.Status.Rejected)
        end)
    end)
end