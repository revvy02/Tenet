local MockNetwork = require(script.Parent.Parent.Parent.Parent.MockNetwork)
local Promise = require(script.Parent.Parent.Parent.Parent.Promise)

local ClientCallback = require(script.Parent.ClientCallback)
local ServerCallback = require(script.Parent.Parent.Server.ServerCallback)

return function()
    describe("ClientCallback.new", function()
        it("should create a new ClientCallback", function()
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

            local clientCallback = ClientCallback.new(mockRemoteFunction)
            
            expect(clientCallback).to.be.a("table")
            expect(getmetatable(clientCallback)).to.equal(ClientCallback)
        end)

        it("should handle inbound middleware properly", function()
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

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

            local serverCallback = ServerCallback.new(mockRemoteFunction)

            local clientCallback = ClientCallback.new(mockRemoteFunction, {
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

            clientCallback:setCallback(function(_, _, message)
                table.insert(payloads, message)
            end)

            serverCallback:callClientAsync("user", "4321", "password", "payload1")
            serverCallback:callClientAsync("user", "1234", "drowssap", "payload2")
            serverCallback:callClientAsync("user", "1234", "password", "payload3")

            expect(dropped[1]).to.equal(1)
            expect(dropped[2]).to.equal(1)

            expect(#payloads).to.equal(1)
            expect(payloads[1]).to.equal("payload3")
        end)

        it("should handle outbound middleware properly", function()
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

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

            local serverCallback = ServerCallback.new(mockRemoteFunction)

            local clientCallback = ClientCallback.new(mockRemoteFunction, {
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

            serverCallback:setCallback(function(_, _, _, payload)
                table.insert(payloads, payload)
            end)

            clientCallback:callServerAsync("4321", "password", "payload1")
            clientCallback:callServerAsync("1234", "drowssap", "payload2")
            clientCallback:callServerAsync("1234", "password", "payload3")

            expect(dropped[1]).to.equal(1)
            expect(dropped[2]).to.equal(1)

            expect(#payloads).to.equal(1)
            expect(payloads[1]).to.equal("payload3")
        end)
    end)

    describe("ClientCallback:setCallback", function()
        it("should resolve any queued requests from the server with the response if the callback doesn't error", function()
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

            local serverCallback = ServerCallback.new(mockRemoteFunction)
            local clientCallback = ClientCallback.new(mockRemoteFunction)

            local count = 0

            local promise1 = serverCallback:callClientAsync("user", 1)
            expect(promise1:getStatus()).to.equal(Promise.Status.Started)

            local promise2 = serverCallback:callClientAsync("user", 2)
            expect(promise2:getStatus()).to.equal(Promise.Status.Started)

            clientCallback:setCallback(function(num)
                return num * 2
            end)

            expect(promise1:getStatus()).to.equal(Promise.Status.Resolved)
            expect(promise2:getStatus()).to.equal(Promise.Status.Resolved)

            count += promise1:expect()
            count += promise2:expect()

            expect(count).to.equal(6)
        end)

        it("should reject any queued requests from the server if the callback errors", function()
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

            local serverCallback = ServerCallback.new(mockRemoteFunction)
            local clientCallback = ClientCallback.new(mockRemoteFunction)

            local promise1 = serverCallback:callClientAsync("user", "z4321")
            expect(promise1:getStatus()).to.equal(Promise.Status.Started)

            local promise2 = serverCallback:callClientAsync("user", "z1234")
            expect(promise2:getStatus()).to.equal(Promise.Status.Started)

            clientCallback:setCallback(function(password)
                assert(password == "z1234", "Uh oh!")

                return "Yay!"
            end)

            expect(promise1:getStatus()).to.equal(Promise.Status.Rejected)
            expect(promise2:getStatus()).to.equal(Promise.Status.Resolved)
            expect(promise2:expect()).to.equal("Yay!")
        end)
    end)

    describe("ClientCallback:flush", function()
        it("should reject any queued requests from server", function()
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

            local serverCallback = ServerCallback.new(mockRemoteFunction)
            local clientCallback = ClientCallback.new(mockRemoteFunction)

            local promise1 = serverCallback:callClientAsync("user")
            expect(promise1:getStatus()).to.equal(Promise.Status.Started)

            clientCallback:flush()
            expect(promise1:getStatus()).to.equal(Promise.Status.Rejected)

            local promise2 = serverCallback:callClientAsync("user")
            expect(promise2:getStatus()).to.equal(Promise.Status.Started)

            clientCallback:setCallback(function(num)
                return true
            end)

            expect(promise2:getStatus()).to.equal(Promise.Status.Resolved)
            expect(promise2:expect()).to.equal(true)
        end)
    end)




    describe("ClientCallback:callServerAsync", function()
        it("should return a promise that resolves with the response from the server if it doesn't error", function()
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

            local serverCallback = ServerCallback.new(mockRemoteFunction)
            local clientCallback = ClientCallback.new(mockRemoteFunction)

            serverCallback:setCallback(function()
                return 1
            end)

            local promise = clientCallback:callServerAsync()

            expect(Promise.is(promise)).to.equal(true)
            expect(promise:getStatus()).to.equal(Promise.Status.Resolved)
            expect(promise:expect()).to.equal(1)
        end)

        it("should return a promise that rejects if the server errors", function()
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

            local serverCallback = ServerCallback.new(mockRemoteFunction)
            local clientCallback = ClientCallback.new(mockRemoteFunction)

            serverCallback:setCallback(function()
                error("Uh oh!")
            end)

            local promise = clientCallback:callServerAsync()

            expect(Promise.is(promise)).to.equal(true)
            expect(promise:getStatus()).to.equal(Promise.Status.Rejected)
        end)

        it("should queue request if the server callback isn't set and resolve once it is", function()
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

            local serverCallback = ServerCallback.new(mockRemoteFunction)
            local clientCallback = ClientCallback.new(mockRemoteFunction)

            local promise = clientCallback:callServerAsync()

            expect(promise:getStatus()).to.equal(Promise.Status.Started)

            serverCallback:setCallback(function()
                return true
            end)

            expect(promise:getStatus()).to.equal(Promise.Status.Resolved)
            expect(promise:expect()).to.equal(true)
        end)
    end)
end