local MockNetwork = require(script.Parent.Parent.Parent.MockNetwork)
local Promise = require(script.Parent.Parent.Parent.Promise)
local Cleaner = require(script.Parent.Parent.Parent.Cleaner)

local ServerCallback = require(script.Parent.ServerCallback)
local ClientCallback = require(script.Parent.Parent.Client.ClientCallback)

return function()
    local cleaner = Cleaner.new()

    local function mapClientCallbacks(id, client)
        return id, cleaner:give(ClientCallback.new({
            remoteFunction = client:getRemoteFunction("remoteFunction"),
        }))
    end

    afterEach(function()
        cleaner:work()
    end)

    afterAll(function()
        cleaner:destroy()
    end)

    describe("ServerCallback.new", function()
        it("should create a new ServerCallback object", function()
            local mockRemoteFunction = cleaner:give(MockNetwork.MockRemoteFunction.new("user"))

            local serverCallback = cleaner:give(ServerCallback.new({
                remoteFunction = mockRemoteFunction,
            }))

            expect(serverCallback).to.be.a("table")
            expect(getmetatable(serverCallback)).to.equal(ServerCallback)
        end)

        it("should handle middleware properly", function()
            local server = cleaner:give(MockNetwork.Server.new({"user1", "user2", "user3"}))
            local clients = server:mapClients()

            local drops = {}
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

            local serverCallback = cleaner:give(ServerCallback.new({
                remoteFunction = server:createRemoteFunction("remoteFunction"),
            }, {
                middleware({
                    index = 1,
                    password = "1234",
                    onDropped = function(player)
                        drops[player] = 1
                    end,
                }),
                middleware({
                    index = 2,
                    password = "password",
                    onDropped = function(player)
                        drops[player] = 2
                    end,
                })
            }))

            local clientCallbacks = server:mapClients(mapClientCallbacks)

            serverCallback:setCallback(function(player, _, _, message)
                messages[player] = message
            end)

            clientCallbacks.user1:callServerAsync("4321", "password", "payload")
            clientCallbacks.user2:callServerAsync("1234", "drowssap", "payload")
            clientCallbacks.user3:callServerAsync("1234", "password", "payload")

            expect(drops[clients.user1]).to.equal(1)
            expect(messages[clients.user1]).to.never.be.ok()

            expect(drops[clients.user2]).to.equal(2)
            expect(messages[clients.user2]).to.never.be.ok()

            expect(drops[clients.user3]).to.never.be.ok()
            expect(messages[clients.user3]).to.equal("payload")
        end)

    end)

    ---

    describe("ServerCallback:setCallback", function()
        it("should resolve queued requests from the client with the response if the callback doesn't error", function()
            local server = cleaner:give(MockNetwork.Server.new({"user1", "user2", "user3"}))
            local clients = server:mapClients()

            local serverCallback = cleaner:give(ServerCallback.new({
                remoteFunction = server:createRemoteFunction("remoteFunction"),
            }))

            local clientCallbacks = server:mapClients(mapClientCallbacks)

            ---------------
            local count = 0

            local promise1 = clientCallback:callServerAsync(1)
            expect(promise1:getStatus()).to.equal(Promise.Status.Started)

            local promise2 = clientCallback:callServerAsync(2)
            expect(promise2:getStatus()).to.equal(Promise.Status.Started)

            serverCallback:setCallback(function(client, num)
                return num * 2
            end)

            expect(promise1:getStatus()).to.equal(Promise.Status.Resolved)
            expect(promise2:getStatus()).to.equal(Promise.Status.Resolved)

            count += promise1:expect()
            count += promise2:expect()

            expect(count).to.equal(6)
        end)

        it("should reject any queued requests from the client if the callback errors", function()
            local mockRemoteFunction = cleaner:give(MockNetwork.MockRemoteFunction.new("user"))

            local clientCallback = ClientCallback.new({
                remoteFunction = mockRemoteFunction,
            })

            local serverCallback = ServerCallback.new({
                remoteFunction = mockRemoteFunction,
            })

            local promise0 = clientCallback:callServerAsync("z4321")
            expect(promise0:getStatus()).to.equal(Promise.Status.Started)

            local promise1 = clientCallback:callServerAsync("z1234")
            expect(promise1:getStatus()).to.equal(Promise.Status.Started)

            serverCallback:setCallback(function(client, password)
                assert(password == "z1234", "Uh oh!")

                return "Yay!"
            end)

            expect(promise0:getStatus()).to.equal(Promise.Status.Rejected)
            expect(promise1:getStatus()).to.equal(Promise.Status.Resolved)
            expect(promise1:expect()).to.equal("Yay!")

            clientCallback:destroy()
            serverCallback:destroy()
            mockRemoteFunction:destroy()
        end)
    end)

    describe("ServerCallback:flush", function()
        it("should reject any queued requests from the client with an error", function()
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

            local clientCallback = ClientCallback.new({
                remoteFunction = mockRemoteFunction,
            })

            local serverCallback = ServerCallback.new({
                remoteFunction = mockRemoteFunction,
            })

            local promise0 = clientCallback:callServerAsync()
            expect(promise0:getStatus()).to.equal(Promise.Status.Started)

            serverCallback:flush()
            expect(promise0:getStatus()).to.equal(Promise.Status.Rejected)

            local promise1 = clientCallback:callServerAsync()
            expect(promise1:getStatus()).to.equal(Promise.Status.Started)

            serverCallback:setCallback(function(client)
                return true
            end)

            expect(promise1:getStatus()).to.equal(Promise.Status.Resolved)
            expect(promise1:expect()).to.equal(true)
            
            clientCallback:destroy()
            serverCallback:destroy()
            mockRemoteFunction:destroy()
        end)
    end)

    describe("ServerCallback:callClientAsync", function()
        it("should return a promise that resolves with the response from the client if it doesn't error", function()
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

            local clientCallback = ClientCallback.new({
                remoteFunction = mockRemoteFunction,
            })

            local serverCallback = ServerCallback.new({
                remoteFunction = mockRemoteFunction,
            })

            clientCallback:setCallback(function()
                return 1
            end)

            local promise = serverCallback:callClientAsync("user")

            expect(Promise.is(promise)).to.equal(true)
            expect(promise:getStatus()).to.equal(Promise.Status.Resolved)
            expect(promise:expect()).to.equal(1)

            clientCallback:destroy()
            serverCallback:destroy()
            mockRemoteFunction:destroy()
        end)

        it("should return a promise that rejects if the client errors", function()
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

            local clientCallback = ClientCallback.new({
                remoteFunction = mockRemoteFunction,
            })

            local serverCallback = ServerCallback.new({
                remoteFunction = mockRemoteFunction,
            })

            clientCallback:setCallback(function()
                error("Uh oh!")
            end)

            local promise = serverCallback:callClientAsync("user")

            expect(Promise.is(promise)).to.equal(true)
            expect(promise:getStatus()).to.equal(Promise.Status.Rejected)

            clientCallback:destroy()
            serverCallback:destroy()
            mockRemoteFunction:destroy()
        end)

        it("should queue request if the client callback isn't set and resolve once it is", function()
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

            local clientCallback = ClientCallback.new({
                remoteFunction = mockRemoteFunction,
            })

            local serverCallback = ServerCallback.new({
                remoteFunction = mockRemoteFunction,
            })

            local promise = serverCallback:callClientAsync("user")

            expect(promise:getStatus()).to.equal(Promise.Status.Started)

            clientCallback:setCallback(function()
                return true
            end)

            expect(promise:getStatus()).to.equal(Promise.Status.Resolved)
            expect(promise:expect()).to.equal(true)

            clientCallback:destroy()
            serverCallback:destroy()
            mockRemoteFunction:destroy()
        end)
    end)

    describe("ServerCallback:destroy", function()
        it("should set destroyed field to true", function()
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

            local serverCallback = ServerCallback.new({
                remoteFunction = mockRemoteFunction,
            })

            serverCallback:destroy()

            expect(serverCallback.destroyed).to.equal(true)
        end)

        it("should reject any queued requests from the client with an error", function()
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

            local clientCallback = ClientCallback.new({
                remoteFunction = mockRemoteFunction,
            })

            local serverCallback = ServerCallback.new({
                remoteFunction = mockRemoteFunction,
            })

            local promise0 = clientCallback:callServerAsync()
            expect(promise0:getStatus()).to.equal(Promise.Status.Started)

            serverCallback:flush()
            expect(promise0:getStatus()).to.equal(Promise.Status.Rejected)

            local promise1 = clientCallback:callServerAsync()
            expect(promise1:getStatus()).to.equal(Promise.Status.Started)

            serverCallback:setCallback(function(num)
                return true
            end)

            expect(promise1:getStatus()).to.equal(Promise.Status.Resolved)
            expect(promise1:expect()).to.equal(true)
            
            clientCallback:destroy()
            serverCallback:destroy()
            mockRemoteFunction:destroy()
        end)
    end)
end