local Promise = require(script.Parent.Parent.Parent.Parent.Promise)

local ServerNetwork = require(script.Parent.Parent.Parent.Server.Primitives.ServerNetwork)

local ClientNetwork = require(script.Parent.ClientNetwork)
local ClientSignal = require(script.Parent.ClientSignal)
local ClientCallback = require(script.Parent.ClientCallback)
local ClientBroadcast = require(script.Parent.ClientBroadcast)

return function()
    describe("ClientNetwork.new", function()
        it("should create a new ClientNetwork object with the name", function()
            local serverNetwork = ServerNetwork.new("game")
            local clientNetwork = ClientNetwork.new("game")

            expect(clientNetwork).to.be.ok()
            expect(getmetatable(clientNetwork)).to.equal(ClientNetwork)

            clientNetwork:_destroy()
            serverNetwork:_destroy()
        end)
    end)

    describe("ClientNetwork:createClientSignal", function()
        it("should create a new ClientSignal object", function()
            local serverNetwork = ServerNetwork.new("game")
            local clientNetwork = ClientNetwork.new("game")
            
            serverNetwork:createServerSignal("signal")
            
            local clientSignal = clientNetwork:createClientSignalAsync("signal"):expect()

            expect(clientSignal).to.be.ok()
            expect(getmetatable(clientSignal)).to.equal(ClientSignal)

            clientNetwork:_destroy()
            serverNetwork:_destroy()
        end)

        it("should throw if a ClientSignal object with that name already exists", function()
            local serverNetwork = ServerNetwork.new("game")
            local clientNetwork = ClientNetwork.new("game")

            serverNetwork:createServerSignal("signal")
            clientNetwork:createClientSignalAsync("signal"):expect()
            
            expect(function()
                clientNetwork:createClientSignalAsync("signal")
            end).to.throw()

            clientNetwork:_destroy()
            serverNetwork:_destroy()
        end)
    end)

    describe("ClientNetwork:getClientSignalAsync", function()
        it("should return a promise that resolves when the ClientSignal object is created", function()
            local serverNetwork = ServerNetwork.new("game")
            local clientNetwork = ClientNetwork.new("game")

            serverNetwork:createServerSignal("signal")

            local promise = clientNetwork:getClientSignalAsync("signal")
            local clientSignal
            
            expect(promise:getStatus()).to.equal(Promise.Status.Started)

            task.spawn(function()
                clientSignal = clientNetwork:createClientSignalAsync("signal"):expect()
            end)

            expect(promise:getStatus()).to.equal(Promise.Status.Resolved)

            expect(clientSignal).to.be.ok()
            expect(promise:expect()).to.equal(clientSignal)

            clientNetwork:_destroy()
            serverNetwork:_destroy()
        end)
    end)

    describe("ClientNetwork:createClientCallback", function()
        it("should create a new ClientCallback object", function()
            local serverNetwork = ServerNetwork.new("game")
            local clientNetwork = ClientNetwork.new("game")

            serverNetwork:createServerCallback("callback")

            local clientCallback = clientNetwork:createClientCallbackAsync("callback"):expect()

            expect(clientCallback).to.be.ok()
            expect(getmetatable(clientCallback)).to.equal(ClientCallback)

            clientNetwork:_destroy()
            serverNetwork:_destroy()
        end)
    end)

    describe("ClientNetwork:getClientCallbackAsync", function()
        it("should return a promise that resolves when the ClientCallback object is created", function()
            local serverNetwork = ServerNetwork.new("game")
            local clientNetwork = ClientNetwork.new("game")

            serverNetwork:createServerCallback("callback")

            local promise = clientNetwork:getClientCallbackAsync("callback")
            local clientCallback
            
            expect(promise:getStatus()).to.equal(Promise.Status.Started)

            task.spawn(function()
                clientCallback = clientNetwork:createClientCallbackAsync("callback"):expect()
            end)

            expect(promise:getStatus()).to.equal(Promise.Status.Resolved)

            expect(clientCallback).to.be.ok()
            expect(promise:expect()).to.equal(clientCallback)

            clientNetwork:_destroy()
            serverNetwork:_destroy()
        end)
    end)

    describe("ClientNetwork:createClientBroadcast", function()
        it("should create a new ClientBroadcast object", function()
            local serverNetwork = ServerNetwork.new("game")
            local clientNetwork = ClientNetwork.new("game")

            serverNetwork:createServerBroadcast("broadcast")

            local clientBroadcast = clientNetwork:createClientBroadcastAsync("broadcast"):expect()

            expect(clientBroadcast).to.be.ok()
            expect(getmetatable(clientBroadcast)).to.equal(ClientBroadcast)

            clientNetwork:_destroy()
            serverNetwork:_destroy()
        end)
    end)

    describe("ClientNetwork:getClientBroadcastAsync", function()
        it("should return a promise that resolves when the ClientBroadcast object is created", function()
            local serverNetwork = ServerNetwork.new("game")
            local clientNetwork = ClientNetwork.new("game")

            serverNetwork:createServerBroadcast("broadcast")

            local promise = clientNetwork:getClientBroadcastAsync("broadcast")
            local clientBroadcast
            
            expect(promise:getStatus()).to.equal(Promise.Status.Started)

            task.spawn(function()
                clientBroadcast = clientNetwork:createClientBroadcastAsync("broadcast"):expect()
            end)

            expect(promise:getStatus()).to.equal(Promise.Status.Resolved)

            expect(clientBroadcast).to.be.ok()
            expect(promise:expect()).to.equal(clientBroadcast)

            clientNetwork:_destroy()
            serverNetwork:_destroy()
        end)
    end)
end