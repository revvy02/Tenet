local MockNetwork = require(script.Parent.Parent.Parent.Parent.MockNetwork)
local Promise = require(script.Parent.Parent.Parent.Parent.Promise)
local TrueSignal = require(script.Parent.Parent.Parent.Parent.TrueSignal)

local ClientBroadcast = require(script.Parent.Parent.Parent.Client.Primitives.ClientBroadcast)
local ServerBroadcast = require(script.Parent.ServerBroadcast)

return function()
    local function mapClientBroadcasts(id, client)
        return id, ClientBroadcast.new(client:getRemoteEvent("remoteEvent"), client:getRemoteFunction("remoteFunction"))
    end

    describe("AtomicChannelServer:getSubscribers", function()
        it("should return a list of players that are subscribed to the atomic channel", function()
            local server = MockNetwork.Server.new({"user1", "user2", "user3"})
            local clients = server:mapClients()

            local serverBroadcast = ServerBroadcast.new(server:createRemoteEvent("remoteEvent"), server:createRemoteFunction("remoteFunction"))

            local acServer = serverBroadcast:createAtomicChannel("store")

            acServer:subscribe(clients.user1)
            acServer:subscribe(clients.user2)
            
            local list = acServer:getSubscribers()

            expect(table.find(list, clients.user1)).to.be.ok()
            expect(table.find(list, clients.user2)).to.be.ok()
            expect(table.find(list, clients.user3)).to.never.be.ok()
        end)
    end)

    describe("AtomicChannelServer:isSubscribed", function()
        it("should return whether or not the player is subscribed to the atomic channel", function()
            local server = MockNetwork.Server.new({"user1", "user2", "user3"})
            local clients = server:mapClients()

            local serverBroadcast = ServerBroadcast.new(server:createRemoteEvent("remoteEvent"), server:createRemoteFunction("remoteFunction"))

            local acServer = serverBroadcast:createAtomicChannel("store")

            acServer:subscribe(clients.user1)
            acServer:subscribe(clients.user2)
            
            expect(acServer:isSubscribed(clients.user1)).to.equal(true)
            expect(acServer:isSubscribed(clients.user2)).to.equal(true)
            expect(acServer:isSubscribed(clients.user3)).to.equal(false)
        end)
    end)

    describe("AtomicChannelServer:subscribe", function()
        it("should create the atomic channel on the client with the current server state", function()
            local server = MockNetwork.Server.new({"user1", "user2"})
            local clients = server:mapClients()

            local serverBroadcast = ServerBroadcast.new(server:createRemoteEvent("remoteEvent"), server:createRemoteFunction("remoteFunction"))
            local clientBroadcasts = server:mapClients(mapClientBroadcasts)

            local acServer = serverBroadcast:createAtomicChannel("store", {
                xp = 1000,
                inv = {"gun"},
            })

            acServer:subscribe(clients.user1)

            local acClients = {
                user1 = clientBroadcasts.user1:getChannel("store"),
                user2 = clientBroadcasts.user2:getChannel("store"),
            }

            expect(acClients.user1).to.be.ok()
            expect(acClients.user1:getValue("xp")).to.equal(1000)
            expect(acClients.user1:getValue("inv")[1]).to.equal("gun")
            
            expect(acClients.user2).to.never.be.ok()
        end)

        it("should fire the subscribed signal on the client", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

            local serverBroadcast = ServerBroadcast.new(mockRemoteEvent, mockRemoteFunction)
            local clientBroadcast = ClientBroadcast.new(mockRemoteEvent, mockRemoteFunction)

            local acServer = serverBroadcast:createAtomicChannel("store", {
                xp = 1000,
                inv = {"gun"},
            })

            local promise = clientBroadcast.subscribed:promise()

            expect(promise:getStatus()).to.equal(Promise.Status.Started)

            acServer:subscribe("user")
            
            expect(promise:getStatus()).to.equal(Promise.Status.Resolved)
            expect(select(1, promise:expect())).to.equal("store")
        end)

        it("should fire the subscribed signal on the server", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

            local serverBroadcast = ServerBroadcast.new(mockRemoteEvent, mockRemoteFunction)
            local clientBroadcast = ClientBroadcast.new(mockRemoteEvent, mockRemoteFunction)

            local acServer = serverBroadcast:createAtomicChannel("store", {
                xp = 1000,
                inv = {"gun"},
            })

            local promise = acServer.subscribed:promise()

            expect(promise:getStatus()).to.equal(Promise.Status.Started)

            acServer:subscribe("user")
            
            expect(promise:getStatus()).to.equal(Promise.Status.Resolved)
            expect(select(1, promise:expect())).to.equal("user")
        end)
    end)

    describe("AtomicChannelServer:unsubscribe", function()
        it("should remove the atomic channel on the client", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

            local serverBroadcast = ServerBroadcast.new(mockRemoteEvent, mockRemoteFunction)
            local clientBroadcast = ClientBroadcast.new(mockRemoteEvent, mockRemoteFunction)

            local acServer = serverBroadcast:createAtomicChannel("store", {
                xp = 1000,
                inv = {"gun"},
            })

            acServer:subscribe("user")

            expect(clientBroadcast:getChannel("store")).to.be.ok()

            acServer:unsubscribe("user")

            expect(clientBroadcast:getChannel("store")).to.never.be.ok()
        end)

        it("should fire the unsubscribed signal on the client", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

            local serverBroadcast = ServerBroadcast.new(mockRemoteEvent, mockRemoteFunction)
            local clientBroadcast = ClientBroadcast.new(mockRemoteEvent, mockRemoteFunction)

            local acServer = serverBroadcast:createAtomicChannel("store", {
                xp = 1000,
                inv = {"gun"},
            })

            local promise = clientBroadcast.unsubscribed:promise()

            expect(promise:getStatus()).to.equal(Promise.Status.Started)

            acServer:subscribe("user")
            acServer:unsubscribe("user")
            
            expect(promise:getStatus()).to.equal(Promise.Status.Resolved)
            expect(promise:expect()).to.equal("store")
        end)

        it("should fire the unsubscribed signal on the server", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

            local serverBroadcast = ServerBroadcast.new(mockRemoteEvent, mockRemoteFunction)

            local acServer = serverBroadcast:createAtomicChannel("store", {
                xp = 1000,
                inv = {"gun"},
            })

            local promise = acServer.unsubscribed:promise()

            expect(promise:getStatus()).to.equal(Promise.Status.Started)

            acServer:subscribe("user")
            acServer:unsubscribe("user")

            expect(promise:getStatus()).to.equal(Promise.Status.Resolved)
            expect(select(1, promise:expect())).to.equal("user")
        end)
    end)

    describe("AtomicChannelServer:dispatch", function()
        it("should properly update the server", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

            local serverBroadcast = ServerBroadcast.new(mockRemoteEvent, mockRemoteFunction)

            local acServer = serverBroadcast:createAtomicChannel("store", {
                xp = 1000,
                inv = {"gun"},
            })

            local changedPromise = acServer.changed:promise()
            local reducedPromise = acServer.reduced:promise()

            acServer:dispatch("xp", "setValue", 2000)

            expect(acServer:getValue("xp")).to.equal(2000)

            expect(select(1, changedPromise:expect())).to.equal("xp")
            expect(select(2, changedPromise:expect()).xp).to.equal(2000)
            expect(select(3, changedPromise:expect()).xp).to.equal(1000)

            expect(select(1, reducedPromise:expect())).to.equal("xp")
            expect(select(2, reducedPromise:expect())).to.equal("setValue")
            expect(select(3, reducedPromise:expect())).to.equal(2000)
        end)

        it("should properly update subscribed  clients", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

            local serverBroadcast = ServerBroadcast.new(mockRemoteEvent, mockRemoteFunction)
            local clientBroadcast = ClientBroadcast.new(mockRemoteEvent, mockRemoteFunction)

            local acServer = serverBroadcast:createAtomicChannel("store", {
                xp = 1000,
                inv = {"gun"},
            })

            acServer:subscribe("user")

            local acClient = clientBroadcast:getChannel("store")

            local changedPromise = acClient.changed:promise()
            local reducedPromise = acClient.reduced:promise()

            acServer:dispatch("xp", "setValue", 2000)

            expect(acServer:getValue("xp")).to.equal(2000)

            expect(select(1, changedPromise:expect())).to.equal("xp")
            expect(select(2, changedPromise:expect()).xp).to.equal(2000)
            expect(select(3, changedPromise:expect()).xp).to.equal(1000)

            expect(select(1, reducedPromise:expect())).to.equal("xp")
            expect(select(2, reducedPromise:expect())).to.equal("setValue")
            expect(select(3, reducedPromise:expect())).to.equal(2000)
        end)
    end)

    describe("AtomicChannelServer:getValue", function()
        it("should return a value that changes properly from server changes", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

            local serverBroadcast = ServerBroadcast.new(mockRemoteEvent, mockRemoteFunction)

            local acServer = serverBroadcast:createAtomicChannel("store", {
                xp = 0,
                inv = {},
            })

            expect(acServer:getValue("xp")).to.equal(0)
            expect(acServer:getValue("inv")[1]).to.equal(nil)

            acServer:dispatch("xp", "setValue", 1000)
            acServer:dispatch("inv", "insertValue", "gun")

            expect(acServer:getValue("xp")).to.equal(1000)
            expect(acServer:getValue("inv")[1]).to.equal("gun")
        end)
    end)

    describe("AtomicChannelServer:getChangedSignal", function()
        it("should return a changed signal that is fired properly from server changes", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

            local serverBroadcast = ServerBroadcast.new(mockRemoteEvent, mockRemoteFunction)

            local acServer = serverBroadcast:createAtomicChannel("store", {
                xp = 0,
                inv = {},
            })

            acServer:subscribe("user")

            local xpSignal = acServer:getChangedSignal("xp")
            local invSignal = acServer:getChangedSignal("inv")

            expect(xpSignal).to.be.a("table")
            expect(getmetatable(xpSignal)).to.equal(TrueSignal)

            expect(invSignal).to.be.a("table")
            expect(getmetatable(invSignal)).to.equal(TrueSignal)

            expect(acServer:getValue("xp")).to.equal(0)
            expect(acServer:getValue("inv")[1]).to.equal(nil)

            local xpPromise = xpSignal:promise()
            local invPromise = invSignal:promise()

            acServer:dispatch("xp", "setValue", 1000)
            acServer:dispatch("inv", "insertValue", "gun")

            expect(select(1, xpPromise:expect())).to.equal(1000)
            expect(select(2, xpPromise:expect())).to.equal(0)

            expect(select(1, invPromise:expect())[1]).to.equal("gun")
            expect(select(2, invPromise:expect())[1]).to.equal(nil)
        end)
    end)

    describe("AtomicChannelServer:getReducedSignal", function()
        it("should return a reduced signal that is fired properly from server changes", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")
            
            local serverBroadcast = ServerBroadcast.new(mockRemoteEvent, mockRemoteFunction)

            local acServer = serverBroadcast:createAtomicChannel("store", {
                xp = 0,
                inv = {},
            })

            acServer:subscribe("user")

            local xpSignal = acServer:getReducedSignal("xp", "setValue")
            local invSignal = acServer:getReducedSignal("inv", "insertValue")

            expect(xpSignal).to.be.a("table")
            expect(getmetatable(xpSignal)).to.equal(TrueSignal)

            expect(invSignal).to.be.a("table")
            expect(getmetatable(invSignal)).to.equal(TrueSignal)

            expect(acServer:getValue("xp")).to.equal(0)
            expect(acServer:getValue("inv")[1]).to.equal(nil)

            local xpPromise = xpSignal:promise()
            local invPromise = invSignal:promise()

            acServer:dispatch("xp", "setValue", 1000)
            acServer:dispatch("inv", "insertValue", "gun")

            expect(xpPromise:expect()).to.equal(1000)
            expect(invPromise:expect()).to.equal("gun")
        end)
    end)
end