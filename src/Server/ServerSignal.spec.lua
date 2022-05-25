return function()
    local MockNetwork = require(script.Parent.Parent.Parent.MockNetwork)
    
    local ServerSignal = require(script.Parent.ServerSignal)

    describe("ServerSignal.new", function()
        it("should create a new ServerSignal object", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new()

            local serverSignal = ServerSignal.new({
                remoteEvent = mockRemoteEvent,
            })

            expect(serverSignal).to.be.ok()
            expect(ServerSignal.is(serverSignal)).to.equal(true)

            serverSignal:destroy()
            mockRemoteEvent:destroy()
        end)

        it("should properly handle middleware", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new()

            local dropped = false
            local passed = false
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
                passed = true
            end)

            mockRemoteEvent:fireServer("4321", "message")
            expect(dropped).to.equal(true)
            expect(passed).to.equal(false)
            expect(message).to.equal(nil)

            mockRemoteEvent:fireServer("1234", "message")
            expect(passed).to.equal(true)
            expect(message).to.equal("message")

            serverSignal:destroy()
            mockRemoteEvent:destroy()
        end)
    end)

    describe("ServerSignal.is", function()
        it("should return true if the passed object is a ServerSignal instance", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new()

            local serverSignal = ServerSignal.new({
                remoteEvent = mockRemoteEvent,
            })

            expect(ServerSignal.is(serverSignal)).to.equal(true)

            serverSignal:destroy()
            mockRemoteEvent:destroy()
        end)

        it("should return false if the passed object is not a ServerSignal instance", function()
            expect(ServerSignal.is(false)).to.equal(false)
            expect(ServerSignal.is(true)).to.equal(false)
            expect(ServerSignal.is(0)).to.equal(false)
            expect(ServerSignal.is({})).to.equal(false)
        end)
    end)

    describe("ServerSignal:flush", function()
        it("should flush any queued requests", function()

        end)
    end)

    describe("ServerSignal:fireClient", function()
        it("should fire the cliet with the passed args", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")
            local num

            local serverSignal = ServerSignal.new({
                remoteEvent = mockRemoteEvent,
            })

            mockRemoteEvent.OnClientEvent:Connect(function(...)
                num = ...
            end)

            serverSignal:fireClient("user", 1)

            expect(num).to.equal(1)

            serverSignal:destroy()
            mockRemoteEvent:destroy()
        end)
    end)

    describe("ServerSignal:fireClients", function()
        it("should fire each of the specified clients", function()
            
        end)
    end)

    describe("ServerSignal:fireAllClientsExcept", function()
        
    end)

    describe("ServerSignal:fireAllClients", function()

    end)

    describe("ServerSignal:destroy", function()

    end)
end