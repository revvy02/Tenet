local MockNetwork = require(script.Parent.Parent.Parent.MockNetwork)
local Promise = require(script.Parent.Parent.Parent.Promise)

local ServerCallback = require(script.Parent.ServerCallback)
local ClientCallback = require(script.Parent.Parent.Client.ClientCallback)

return function()
    describe("ServerCallback.new", function()
        it("should create a new ServerCallback object", function()
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

            local serverCallback = ServerCallback.new({
                remoteFunction = mockRemoteFunction,
            })

            expect(serverCallback).to.be.a("table")
            expect(getmetatable(serverCallback)).to.equal(ServerCallback)

            serverCallback:destroy()
            mockRemoteFunction:destroy()
        end)

        it("should handle middleware properly", function()
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

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

            local serverCallback = ServerCallback.new({
                remoteFunction = mockRemoteFunction,
            }, {
                passwordMiddleware({
                    password = "1234",
                    onDropped = function()
                        dropped = true
                    end,
                })
            }) 

            serverCallback:setCallback(function(client, password, ...)
                message = ...
            end)

            mockRemoteFunction:invokeServer("4321", "message")
            expect(dropped).to.equal(true)
            expect(message).to.equal(nil)

            mockRemoteFunction:invokeServer("1234", "message")
            expect(message).to.equal("message")

            serverCallback:destroy()
            mockRemoteFunction:destroy()
        end)
    end)

    describe("ServerCallback:setCallback", function()
        it("should resolve queued requests from the client with the response if the callback doesn't error", function()
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

            local clientCallback = ClientCallback.new({
                remoteFunction = mockRemoteFunction,
            })

            local serverCallback = ServerCallback.new({
                remoteFunction = mockRemoteFunction,
            })

            local count = 0

            local promise0 = clientCallback:callServerAsync(1)
            expect(promise0:getStatus()).to.equal(Promise.Status.Started)

            local promise1 = clientCallback:callServerAsync(2)
            expect(promise1:getStatus()).to.equal(Promise.Status.Started)

            serverCallback:setCallback(function(client, num)
                return num * 2
            end)

            expect(promise0:getStatus()).to.equal(Promise.Status.Resolved)
            expect(promise1:getStatus()).to.equal(Promise.Status.Resolved)

            count += promise0:expect()
            count += promise1:expect()

            expect(count).to.equal(6)

            clientCallback:destroy()
            serverCallback:destroy()
            mockRemoteFunction:destroy()
        end)

        it("should reject any queued requests from the client if the callback errors", function()
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

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