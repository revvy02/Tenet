local MockNetwork = require(script.Parent.Parent.Parent.MockNetwork)
local Promise = require(script.Parent.Parent.Parent.Promise)
local Cleaner = require(script.Parent.Parent.Parent.Cleaner)

local ClientCallback = require(script.Parent.ClientCallback)
local ServerCallback = require(script.Parent.Parent.Server.ServerCallback)

return function()
    local cleaner = Cleaner.new()
    
    afterEach(function()
        cleaner:work()
    end)

    afterAll(function()
        cleaner:destroy()
    end)

    describe("ClientCallback.new", function()
        it("should create a new ClientCallback", function()
            local mockRemoteFunction = cleaner:give(MockNetwork.MockRemoteFunction.new("user"))

            local clientCallback = cleaner:give(ClientCallback.new(mockRemoteFunction))
            
            expect(clientCallback).to.be.a("table")
            expect(getmetatable(clientCallback)).to.equal(ClientCallback)
        end)
    end)

    describe("ClientCallback:setCallback", function()
        it("should resolve any queued requests from the server with the response if the callback doesn't error", function()
            local mockRemoteFunction = cleaner:give(MockNetwork.MockRemoteFunction.new("user"))

            local serverCallback = cleaner:give(ServerCallback.new(mockRemoteFunction))
            local clientCallback = cleaner:give(ClientCallback.new(mockRemoteFunction))

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
            local mockRemoteFunction = cleaner:give(MockNetwork.MockRemoteFunction.new("user"))

            local serverCallback = cleaner:give(ServerCallback.new(mockRemoteFunction))
            local clientCallback = cleaner:give(ClientCallback.new(mockRemoteFunction))

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
            local mockRemoteFunction = cleaner:give(MockNetwork.MockRemoteFunction.new("user"))

            local serverCallback = cleaner:give(ServerCallback.new(mockRemoteFunction))
            local clientCallback = cleaner:give(ClientCallback.new(mockRemoteFunction))

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
            local mockRemoteFunction = cleaner:give(MockNetwork.MockRemoteFunction.new("user"))

            local serverCallback = cleaner:give(ServerCallback.new(mockRemoteFunction))
            local clientCallback = cleaner:give(ClientCallback.new(mockRemoteFunction))

            serverCallback:setCallback(function()
                return 1
            end)

            local promise = clientCallback:callServerAsync()

            expect(Promise.is(promise)).to.equal(true)
            expect(promise:getStatus()).to.equal(Promise.Status.Resolved)
            expect(promise:expect()).to.equal(1)
        end)

        it("should return a promise that rejects if the server errors", function()
            local mockRemoteFunction = cleaner:give(MockNetwork.MockRemoteFunction.new("user"))

            local serverCallback = cleaner:give(ServerCallback.new(mockRemoteFunction))
            local clientCallback = cleaner:give(ClientCallback.new(mockRemoteFunction))

            serverCallback:setCallback(function()
                error("Uh oh!")
            end)

            local promise = clientCallback:callServerAsync()

            expect(Promise.is(promise)).to.equal(true)
            expect(promise:getStatus()).to.equal(Promise.Status.Rejected)
        end)

        it("should queue request if the server callback isn't set and resolve once it is", function()
            local mockRemoteFunction = cleaner:give(MockNetwork.MockRemoteFunction.new("user"))

            local serverCallback = cleaner:give(ServerCallback.new(mockRemoteFunction))
            local clientCallback = cleaner:give(ClientCallback.new(mockRemoteFunction))

            local promise = clientCallback:callServerAsync()

            expect(promise:getStatus()).to.equal(Promise.Status.Started)

            serverCallback:setCallback(function()
                return true
            end)

            expect(promise:getStatus()).to.equal(Promise.Status.Resolved)
            expect(promise:expect()).to.equal(true)
        end)
    end)







    describe("ClientCallback:destroy", function()
        it("should set destroyed field to true", function()
            local mockRemoteFunction = cleaner:give(MockNetwork.MockRemoteFunction.new("user"))

            local clientCallback = ClientCallback.new(mockRemoteFunction)

            clientCallback:destroy()

            expect(clientCallback.destroyed).to.equal(true)
        end)
        
        it("should reject any queued requests from server", function()
            local mockRemoteFunction = cleaner:give(MockNetwork.MockRemoteFunction.new("user"))

            local serverCallback = cleaner:give(ServerCallback.new(mockRemoteFunction))
            local clientCallback = ClientCallback.new(mockRemoteFunction)

            local promise1 = serverCallback:callClientAsync("user")
            expect(promise1:getStatus()).to.equal(Promise.Status.Started)

            clientCallback:destroy()
            expect(promise1:getStatus()).to.equal(Promise.Status.Rejected)
        end)
    end)
end