local Promise = require(script.Parent.Parent.Parent.Parent.Promise)

local ServerNetwork = require(script.Parent.ServerNetwork)
local ServerSignal = require(script.Parent.ServerSignal)
local ServerCallback = require(script.Parent.ServerCallback)
local ServerBroadcast = require(script.Parent.ServerBroadcast)

return function()
    describe("ServerNetwork.new", function()
        it("should create a new ServerNetwork object with the name", function()
            local serverNetwork = ServerNetwork.new("game")

            expect(serverNetwork).to.be.ok()
            expect(getmetatable(serverNetwork)).to.equal(ServerNetwork)

            serverNetwork:_destroy()
        end)

        it("should throw if a ServerNetwork object with that name already exists", function()
            local serverNetwork = ServerNetwork.new("game")

            expect(function()
                ServerNetwork.new("game")
            end).to.throw()

            serverNetwork:_destroy()
        end)
    end)

    describe("ServerNetwork:createServerSignal", function()
        it("should create a new ServerSignal object", function()
            local serverNetwork = ServerNetwork.new("game")
            local serverSignal = serverNetwork:createServerSignal("serverSignal")

            expect(serverSignal).to.be.ok()
            expect(getmetatable(serverSignal)).to.equal(ServerSignal)

            serverNetwork:_destroy()
        end)

        it("should throw if a ServerSignal object with that name already exists", function()
            local serverNetwork = ServerNetwork.new("game")
            serverNetwork:createServerSignal("signal")
            
            expect(function()
                serverNetwork:createServerSignal("signal")
            end).to.throw()

            serverNetwork:_destroy()
        end)
    end)

    describe("ServerNetwork:getServerSignalAsync", function()
        it("should return a promise that resolves when the ServerSignal object is created", function()
            local serverNetwork = ServerNetwork.new("game")

            local promise = serverNetwork:getServerSignalAsync("signal")
            local serverSignal
            
            expect(promise:getStatus()).to.equal(Promise.Status.Started)

            task.spawn(function()
                serverSignal = serverNetwork:createServerSignal("signal")
            end)

            expect(promise:getStatus()).to.equal(Promise.Status.Resolved)

            expect(serverSignal).to.be.ok()
            expect(promise:expect()).to.equal(serverSignal)

            serverNetwork:_destroy()
        end)
    end)

    describe("ServerNetwork:createServerCallback", function()
        it("should create a new ServerCallback object", function()
            local serverNetwork = ServerNetwork.new("game")
            local serverCallback = serverNetwork:createServerCallback("callback")

            expect(serverCallback).to.be.ok()
            expect(getmetatable(serverCallback)).to.equal(ServerCallback)

            serverNetwork:_destroy()
        end)
    end)

    describe("ServerNetwork:getServerCallbackAsync", function()
        it("should return a promise that resolves when the ServerCallback object is created", function()
            local serverNetwork = ServerNetwork.new("game")

            local promise = serverNetwork:getServerCallbackAsync("callback")
            local serverCallback
            
            expect(promise:getStatus()).to.equal(Promise.Status.Started)

            task.spawn(function()
                serverCallback = serverNetwork:createServerCallback("callback")
            end)

            expect(promise:getStatus()).to.equal(Promise.Status.Resolved)

            expect(serverCallback).to.be.ok()
            expect(promise:expect()).to.equal(serverCallback)

            serverNetwork:_destroy()
        end)
    end)

    describe("ServerNetwork:createServerBroadcast", function()
        it("should create a new ServerBroadcast object", function()
            local serverNetwork = ServerNetwork.new("game")
            local serverBroadcast = serverNetwork:createServerBroadcast("broadcast")

            expect(serverBroadcast).to.be.ok()
            expect(getmetatable(serverBroadcast)).to.equal(ServerBroadcast)

            serverNetwork:_destroy()
        end)
    end)

    describe("ServerNetwork:getServerBroadcastAsync", function()
        it("should return a promise that resolves when the ServerBroadcast object is created", function()
            local serverNetwork = ServerNetwork.new("game")

            local promise = serverNetwork:getServerBroadcastAsync("broadcast")
            local serverBroadcast
            
            expect(promise:getStatus()).to.equal(Promise.Status.Started)

            task.spawn(function()
                serverBroadcast = serverNetwork:createServerBroadcast("broadcast")
            end)

            expect(promise:getStatus()).to.equal(Promise.Status.Resolved)

            expect(serverBroadcast).to.be.ok()
            expect(promise:expect()).to.equal(serverBroadcast)

            serverNetwork:_destroy()
        end)
    end)
end