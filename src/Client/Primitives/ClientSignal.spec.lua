local MockNetwork = require(script.Parent.Parent.Parent.MockNetwork)
local Promise = require(script.Parent.Parent.Parent.Promise)
local Cleaner = require(script.Parent.Parent.Parent.Cleaner)

local ClientSignal = require(script.Parent.ClientSignal)
local ServerSignal = require(script.Parent.Parent.Server.ServerSignal)

return function()
    describe("ClientSignal.new", function()
        it("should create a new ClientSignal", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")

            local clientSignal = ClientSignal.new(mockRemoteEvent)
            
            expect(clientSignal).to.be.a("table")
            expect(getmetatable(clientSignal)).to.equal(ClientSignal)
        end)

        it("should handle inbound middleware properly", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")

            local dropped = {0, 0}
            local payloads = {}

            local function middleware(config)
                return function(nextMiddleware, _)
                    return function(...)
                        if select(config.index, ...) == config.password then
                            return nextMiddleware(...)
                        else
                            config.onDropped(...)
                        end
                    end
                end
            end

            local serverSignal = ServerSignal.new(mockRemoteEvent)

            local clientSignal = ClientSignal.new(mockRemoteEvent, {
                inbound = {
                    middleware({
                        index = 1,
                        password = "1234",
                        onDropped = function()
                            dropped[1] += 1
                        end,
                    }),
                    middleware({
                        index = 2,
                        password = "password",
                        onDropped = function()
                            dropped[2] += 1
                        end,
                    })
                },
            })

            clientSignal:connect(function(_, _, message)
                table.insert(payloads, message)
            end)

            serverSignal:fireClient("user", "4321", "password", "payload1")
            serverSignal:fireClient("user", "1234", "drowssap", "payload2")
            serverSignal:fireClient("user", "1234", "password", "payload3")

            expect(dropped[1]).to.equal(1)
            expect(dropped[2]).to.equal(1)

            expect(#payloads).to.equal(1)
            expect(payloads[1]).to.equal("payload3")
        end)

        it("should handle outbound middleware properly", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")

            local dropped = {0, 0}
            local payloads = {}

            local function middleware(config)
                return function(nextMiddleware, _)
                    return function(...)
                        if select(config.index, ...) == config.password then
                            return nextMiddleware(...)
                        else
                            config.onDropped(...)
                        end
                    end
                end
            end

            local serverSignal = ServerSignal.new(mockRemoteEvent)

            local clientSignal = ClientSignal.new(mockRemoteEvent, {
                outbound = {
                    middleware({
                        index = 1,
                        password = "1234",
                        onDropped = function()
                            dropped[1] += 1
                        end,
                    }),
                    middleware({
                        index = 2,
                        password = "password",
                        onDropped = function()
                            dropped[2] += 1
                        end,
                    })
                },
            })

            serverSignal:connect(function(_, _, _, payload)
                table.insert(payloads, payload)
            end)

            clientSignal:fireServer("4321", "password", "payload1")
            clientSignal:fireServer("1234", "drowssap", "payload2")
            clientSignal:fireServer("1234", "password", "payload3")

            expect(dropped[1]).to.equal(1)
            expect(dropped[2]).to.equal(1)

            expect(#payloads).to.equal(1)
            expect(payloads[1]).to.equal("payload3")
        end)
    end)

    describe("ClientSignal:fireServer", function()
        it("should fire the server with the args", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")

            local serverSignal = ServerSignal.new(mockRemoteEvent)
            local clientSignal = ClientSignal.new(mockRemoteEvent)

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
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")

            local serverSignal = ServerSignal.new(mockRemoteEvent)
            local clientSignal = ClientSignal.new(mockRemoteEvent)

            local count = 0

            clientSignal:fireServer(1)
            clientSignal:fireServer(2)
            clientSignal:fireServer(3)

            serverSignal:connect(function(client, num)
                count += num
            end)
            
            expect(count).to.equal(6)
        end)

        it("should be able to pass tables with instance keys", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")

            local serverSignal = ServerSignal.new(mockRemoteEvent)
            local clientSignal = ClientSignal.new(mockRemoteEvent)

            local part = Instance.new("Part")
            local promise = serverSignal:promise()

            clientSignal:fireServer({
                [part] = 1,
            })

            expect(promise:getStatus()).to.equal(Promise.Status.Resolved)
            expect(select(2, promise:expect())[part]).to.equal(1)
        end)
    end)

    describe("ClientSignal:flush", function()
        it("should prevent flushed args from being processed by an activating connection", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")

            local serverSignal = ServerSignal.new(mockRemoteEvent)
            local clientSignal = ClientSignal.new(mockRemoteEvent)

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
        end)
    end)

    describe("ClientSignal:connect", function()
        it("should process queued args when an activating conection is made", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")

            local serverSignal = ServerSignal.new(mockRemoteEvent)
            local clientSignal = ClientSignal.new(mockRemoteEvent)
            
            local count = 0

            serverSignal:fireClient("user", 1)
            serverSignal:fireClient("user", 2)
            serverSignal:fireClient("user", 3)

            clientSignal:connect(function(num)
                count += num
            end)
            
            expect(count).to.equal(6)
        end)

        it("should return a connection that works properly", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")

            local serverSignal = ServerSignal.new(mockRemoteEvent)
            local clientSignal = ClientSignal.new(mockRemoteEvent)

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
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")

            local serverSignal = ServerSignal.new(mockRemoteEvent)
            local clientSignal = ClientSignal.new(mockRemoteEvent)

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
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")

            local serverSignal = ServerSignal.new(mockRemoteEvent)
            local clientSignal = ClientSignal.new(mockRemoteEvent)

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
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new()

            local clientSignal = ClientSignal.new(mockRemoteEvent)

            clientSignal:destroy()

            expect(clientSignal.destroyed).to.equal(true)
        end)
        
        it("should cleanup middleware", function()
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

            local clientSignal = ClientSignal.new(mockRemoteEvent, {
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

            clientSignal:destroy()

            expect(destroyed1).to.equal(true)
            expect(destroyed2).to.equal(true)
            expect(destroyed3).to.equal(true)
            expect(destroyed4).to.equal(true)
        end)
    end)
end