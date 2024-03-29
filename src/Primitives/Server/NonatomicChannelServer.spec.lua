local MockNetwork = require(script.Parent.Parent.Parent.Parent.MockNetwork)
local Promise = require(script.Parent.Parent.Parent.Parent.Promise)
local TrueSignal = require(script.Parent.Parent.Parent.Parent.TrueSignal)

local ClientBroadcast = require(script.Parent.Parent.Client.ClientBroadcast)
local ServerBroadcast = require(script.Parent.ServerBroadcast)

return function()
    local function mapClientBroadcasts(id, client)
        return id, ClientBroadcast.new(client:getRemoteEvent("remoteEvent"), client:getRemoteFunction("remoteFunction"))
    end

    describe("NonatomicChannelServer:getSubscribers", function()
        it("should return a list of players that are subscribed to the nonatomic channel", function()
            local server = MockNetwork.Server.new({"user1", "user2", "user3"})
            local clients = server:mapClients()

            local serverBroadcast = ServerBroadcast.new(server:createRemoteEvent("remoteEvent"), server:createRemoteFunction("remoteFunction"))

            local ncServer = serverBroadcast:createNonatomicChannel("store")

            ncServer:subscribe(clients.user1)
            ncServer:subscribe(clients.user2)
            
            local list = ncServer:getSubscribers()

            expect(table.find(list, clients.user1)).to.be.ok()
            expect(table.find(list, clients.user2)).to.be.ok()
            expect(table.find(list, clients.user3)).to.never.be.ok()
        end)
    end)

    describe("NonatomicChannelServer:getStreamers", function()
        it("should return a list of players that are streamed the passed key", function()
            local server = MockNetwork.Server.new({"user1", "user2", "user3"})
            local clients = server:mapClients()

            local serverBroadcast = ServerBroadcast.new(server:createRemoteEvent("remoteEvent"), server:createRemoteFunction("remoteFunction"))

            local ncServer = serverBroadcast:createNonatomicChannel("store", {
                xp = 1,
                inv = {"gun"}
            })

            ncServer:subscribe(clients.user1)
            ncServer:subscribe(clients.user3)

            ncServer:stream("xp", clients.user1)
            ncServer:stream("xp", clients.user2)

            local list = ncServer:getStreamers("xp")

            expect(table.find(list, clients.user1)).to.be.ok()
            expect(table.find(list, clients.user2)).to.be.ok()
            expect(table.find(list, clients.user3)).to.never.be.ok()
        end)
    end)

    describe("NonatomicChannelServer:getStreamedSubscribers", function()
        it("should return a list of players that are subscribed to the key and streamed the key", function()
            local server = MockNetwork.Server.new({"user1", "user2", "user3"})
            local clients = server:mapClients()

            local serverBroadcast = ServerBroadcast.new(server:createRemoteEvent("remoteEvent"), server:createRemoteFunction("remoteFunction"))

            local ncServer = serverBroadcast:createNonatomicChannel("store", {
                xp = 1,
                inv = {"gun"}
            })

            ncServer:subscribe(clients.user1)
            ncServer:subscribe(clients.user2)

            ncServer:stream("xp", clients.user1)
            ncServer:stream("xp", clients.user3)

            local list = ncServer:getStreamedSubscribers("xp")

            expect(table.find(list, clients.user1)).to.be.ok()
            expect(table.find(list, clients.user2)).to.never.be.ok()
            expect(table.find(list, clients.user3)).to.never.be.ok()
        end)
    end)

    describe("NonatomicChannelServer:isSubscribed", function()
        it("should return whether or not the player is subscribed to the nonatomic channel", function()
            local server = MockNetwork.Server.new({"user1", "user2", "user3"})
            local clients = server:mapClients()

            local serverBroadcast = ServerBroadcast.new(server:createRemoteEvent("remoteEvent"), server:createRemoteFunction("remoteFunction"))

            local ncServer = serverBroadcast:createNonatomicChannel("store")

            ncServer:subscribe(clients.user1)
            ncServer:subscribe(clients.user2)
            
            expect(ncServer:isSubscribed(clients.user1)).to.equal(true)
            expect(ncServer:isSubscribed(clients.user2)).to.equal(true)
            expect(ncServer:isSubscribed(clients.user3)).to.equal(false)
        end)
    end)

    describe("NonatomicChannelServer:isStreamed", function()
        it("should return whether or not the player is streamed the key of the nonatomic channel", function()
            local server = MockNetwork.Server.new({"user1", "user2", "user3"})
            local clients = server:mapClients()

            local serverBroadcast = ServerBroadcast.new(server:createRemoteEvent("remoteEvent"), server:createRemoteFunction("remoteFunction"))

            local ncServer = serverBroadcast:createNonatomicChannel("store", {
                xp = 1,
                inv = {"gun"}
            })

            ncServer:subscribe(clients.user1)
            ncServer:subscribe(clients.user3)

            ncServer:stream("xp", clients.user1)
            ncServer:stream("xp", clients.user2)
            
            expect(ncServer:isStreamed("xp", clients.user1)).to.equal(true)
            expect(ncServer:isStreamed("xp", clients.user2)).to.equal(true)
            expect(ncServer:isStreamed("xp", clients.user3)).to.equal(false)
        end)
    end)

    describe("NonatomicChannelServer:subscribe", function()
        it("should create the nonatomic channel on the client with keys they are streamed", function()
            local server = MockNetwork.Server.new({"user1", "user2"})
            local clients = server:mapClients()

            local serverBroadcast = ServerBroadcast.new(server:createRemoteEvent("remoteEvent"), server:createRemoteFunction("remoteFunction"))
            local clientBroadcasts = server:mapClients(mapClientBroadcasts)

            local ncServer = serverBroadcast:createNonatomicChannel("store", {
                xp = 1000,
                inv = {"gun"},
            })

            ncServer:stream("xp", clients.user1)
            ncServer:stream("inv", clients.user2)

            ncServer:subscribe(clients.user1)

            local ncClients = {
                user1 = clientBroadcasts.user1:getChannel("store"),
                user2 = clientBroadcasts.user2:getChannel("store"),
            }

            expect(ncClients.user1).to.be.ok()
            expect(ncClients.user1:getValue("xp")).to.equal(1000)
            expect(ncClients.user1:getValue("inv")).to.never.be.ok()
            
            expect(ncClients.user2).to.never.be.ok()
        end)

        it("should fire the subscribed signal on the client", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

            local serverBroadcast = ServerBroadcast.new(mockRemoteEvent, mockRemoteFunction)
            local clientBroadcast = ClientBroadcast.new(mockRemoteEvent, mockRemoteFunction)

            local ncServer = serverBroadcast:createNonatomicChannel("store", {
                xp = 1000,
                inv = {"gun"},
            })

            local promise = clientBroadcast.subscribed:promise()

            expect(promise:getStatus()).to.equal(Promise.Status.Started)

            ncServer:subscribe("user")
            
            expect(promise:getStatus()).to.equal(Promise.Status.Resolved)
            expect(select(1, promise:expect())).to.equal("store")
        end)

        it("should fire the subscribed signal on the server", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

            local serverBroadcast = ServerBroadcast.new(mockRemoteEvent, mockRemoteFunction)

            local ncServer = serverBroadcast:createAtomicChannel("store", {
                xp = 1000,
                inv = {"gun"},
            })

            local promise = ncServer.subscribed:promise()

            expect(promise:getStatus()).to.equal(Promise.Status.Started)

            ncServer:subscribe("user")
            
            expect(promise:getStatus()).to.equal(Promise.Status.Resolved)
            expect(select(1, promise:expect())).to.equal("user")
        end)
    end)

    describe("NonatomicChannelServer:unsubscribe", function()
        it("should remove the nonatomic channel on the client", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

            local serverBroadcast = ServerBroadcast.new(mockRemoteEvent, mockRemoteFunction)
            local clientBroadcast = ClientBroadcast.new(mockRemoteEvent, mockRemoteFunction)

            local ncServer = serverBroadcast:createNonatomicChannel("store", {
                xp = 1000,
                inv = {"gun"},
            })

            ncServer:subscribe("user")

            expect(clientBroadcast:getChannel("store")).to.be.ok()

            ncServer:unsubscribe("user")

            expect(clientBroadcast:getChannel("store")).to.never.be.ok()
        end)

        it("should fire the unsubscribed signal on the client", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

            local serverBroadcast = ServerBroadcast.new(mockRemoteEvent, mockRemoteFunction)
            local clientBroadcast = ClientBroadcast.new(mockRemoteEvent, mockRemoteFunction)

            local ncServer = serverBroadcast:createNonatomicChannel("store", {
                xp = 1000,
                inv = {"gun"},
            })

            local promise = clientBroadcast.unsubscribed:promise()

            expect(promise:getStatus()).to.equal(Promise.Status.Started)

            ncServer:subscribe("user")
            ncServer:unsubscribe("user")
            
            expect(promise:getStatus()).to.equal(Promise.Status.Resolved)
            expect(promise:expect()).to.equal("store")
        end)

        it("should fire the unsubscribed signal on the server", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

            local serverBroadcast = ServerBroadcast.new(mockRemoteEvent, mockRemoteFunction)

            local ncServer = serverBroadcast:createNonatomicChannel("store", {
                xp = 1000,
                inv = {"gun"},
            })

            local promise = ncServer.unsubscribed:promise()

            expect(promise:getStatus()).to.equal(Promise.Status.Started)

            ncServer:subscribe("user")
            ncServer:unsubscribe("user")

            expect(promise:getStatus()).to.equal(Promise.Status.Resolved)
            expect(select(1, promise:expect())).to.equal("user")
        end)
    end)

    describe("NonatomicChannelServer:stream", function()
        it("should load the key value on the client if they are subscribed", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

            local serverBroadcast = ServerBroadcast.new(mockRemoteEvent, mockRemoteFunction)
            local clientBroadcast = ClientBroadcast.new(mockRemoteEvent, mockRemoteFunction)

            local ncServer = serverBroadcast:createNonatomicChannel("store", {
                xp = 1000,
                inv = {"gun"},
            })

            ncServer:subscribe("user")

            local ncClient = clientBroadcast:getChannel("store")

            expect(ncClient:getValue("xp")).to.never.be.ok()
            expect(ncClient:getValue("inv")).to.never.be.ok()

            ncServer:stream("xp", "user")

            expect(ncClient:getValue("xp")).to.equal(1000)
            expect(ncClient:getValue("inv")).to.never.be.ok()
        end)

        it("should fire the streamed signal on the client", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

            local serverBroadcast = ServerBroadcast.new(mockRemoteEvent, mockRemoteFunction)
            local clientBroadcast = ClientBroadcast.new(mockRemoteEvent, mockRemoteFunction)

            local ncServer = serverBroadcast:createNonatomicChannel("store", {
                xp = 1000,
                inv = {"gun"},
            })

            ncServer:subscribe("user")

            local ncClient = clientBroadcast:getChannel("store")

            local promise = ncClient.streamed:promise()

            expect(promise:getStatus()).to.equal(Promise.Status.Started)

            ncServer:stream("xp", "user")

            expect(promise:getStatus()).to.equal(Promise.Status.Resolved)

            expect(select(1, promise:expect())).to.equal("xp")
            expect(select(2, promise:expect())).to.equal(1000)
        end)

        it("should fire the streamed signal on the server", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

            local serverBroadcast = ServerBroadcast.new(mockRemoteEvent, mockRemoteFunction)

            local ncServer = serverBroadcast:createNonatomicChannel("store", {
                xp = 1000,
                inv = {"gun"},
            })

            local promise = ncServer.streamed:promise()

            expect(promise:getStatus()).to.equal(Promise.Status.Started)

            ncServer:stream("xp", "user")

            expect(promise:getStatus()).to.equal(Promise.Status.Resolved)

            expect(select(1, promise:expect())).to.equal("xp")
            expect(select(2, promise:expect())).to.equal("user")
        end)
    end)

    describe("NonatomicChannelServer:unstream", function()
        it("should unload the key value on the client if they are subscribed", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

            local serverBroadcast = ServerBroadcast.new(mockRemoteEvent, mockRemoteFunction)
            local clientBroadcast = ClientBroadcast.new(mockRemoteEvent, mockRemoteFunction)

            local ncServer = serverBroadcast:createNonatomicChannel("store", {
                xp = 1000,
                inv = {"gun"},
            })

            ncServer:subscribe("user")

            local ncClient = clientBroadcast:getChannel("store")

            expect(ncClient:getValue("xp")).to.never.be.ok()
            expect(ncClient:getValue("inv")).to.never.be.ok()

            ncServer:stream("xp", "user")

            expect(ncClient:getValue("xp")).to.equal(1000)
            expect(ncClient:getValue("inv")).to.never.be.ok()

            ncServer:unstream("xp", "user")

            expect(ncClient:getValue("xp")).to.never.be.ok()
            expect(ncClient:getValue("inv")).to.never.be.ok()
        end)

        it("should fire the unstreamed signal on the client", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

            local serverBroadcast = ServerBroadcast.new(mockRemoteEvent, mockRemoteFunction)
            local clientBroadcast = ClientBroadcast.new(mockRemoteEvent, mockRemoteFunction)

            local ncServer = serverBroadcast:createNonatomicChannel("store", {
                xp = 1000,
                inv = {"gun"},
            })

            ncServer:subscribe("user")

            local ncClient = clientBroadcast:getChannel("store")

            local promise = ncClient.unstreamed:promise()

            expect(promise:getStatus()).to.equal(Promise.Status.Started)

            ncServer:stream("xp", "user")
            
            expect(promise:getStatus()).to.equal(Promise.Status.Started)

            ncServer:unstream("xp", "user")

            expect(promise:getStatus()).to.equal(Promise.Status.Resolved)

            expect(select(1, promise:expect())).to.equal("xp")
        end)

        it("should fire the unstreamed signal on the server", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

            local serverBroadcast = ServerBroadcast.new(mockRemoteEvent, mockRemoteFunction)

            local ncServer = serverBroadcast:createNonatomicChannel("store", {
                xp = 1000,
                inv = {"gun"},
            })

            local promise = ncServer.unstreamed:promise()

            expect(promise:getStatus()).to.equal(Promise.Status.Started)

            ncServer:stream("xp", "user")
            
            expect(promise:getStatus()).to.equal(Promise.Status.Started)

            ncServer:unstream("xp", "user")

            expect(promise:getStatus()).to.equal(Promise.Status.Resolved)

            expect(select(1, promise:expect())).to.equal("xp")
            expect(select(2, promise:expect())).to.equal("user")
        end)
    end)

    describe("NonatomicChannelServer:dispatch", function()
        it("should properly update the server", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

            local serverBroadcast = ServerBroadcast.new(mockRemoteEvent, mockRemoteFunction)

            local ncServer = serverBroadcast:createNonatomicChannel("store", {
                xp = 1000,
                inv = {"gun"},
            })

            local changedPromise = ncServer.changed:promise()
            local reducedPromise = ncServer.reduced:promise()

            ncServer:dispatch("setValue", "xp", 2000)

            expect(ncServer:getValue("xp")).to.equal(2000)

            expect(select(1, changedPromise:expect())).to.equal("xp")
            expect(select(2, changedPromise:expect()).xp).to.equal(2000)
            expect(select(3, changedPromise:expect()).xp).to.equal(1000)

            expect(select(1, reducedPromise:expect())).to.equal("setValue")
            expect(select(2, reducedPromise:expect())).to.equal("xp")
            expect(select(3, reducedPromise:expect())).to.equal(2000)
        end)

        it("should properly update subscribed and streamed clients", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

            local serverBroadcast = ServerBroadcast.new(mockRemoteEvent, mockRemoteFunction)
            local clientBroadcast = ClientBroadcast.new(mockRemoteEvent, mockRemoteFunction)

            local ncServer = serverBroadcast:createNonatomicChannel("store", {
                xp = 1000,
                inv = {"gun"},
            })

            ncServer:subscribe("user")
            ncServer:stream("xp", "user")

            local ncClient = clientBroadcast:getChannel("store")

            local changedPromise = ncClient.changed:promise()
            local reducedPromise = ncClient.reduced:promise()

            expect(ncClient:getValue("xp")).to.equal(1000)
            expect(ncClient:getValue("inv")).to.never.be.ok()

            ncServer:dispatch("setValue", "xp", 2000)
            ncServer:dispatch("insertValue", "inv", "sword")

            expect(changedPromise:getStatus()).to.equal(Promise.Status.Resolved)

            expect(select(1, changedPromise:expect())).to.equal("xp")
            expect(select(2, changedPromise:expect()).xp).to.equal(2000)
            expect(select(3, changedPromise:expect()).xp).to.equal(1000)

            expect(ncClient:getValue("xp")).to.equal(2000)
            expect(ncClient:getValue("inv")).to.never.be.ok()

            ncServer:stream("inv", "user")

            expect(select(1, reducedPromise:expect())).to.equal("setValue")
            expect(select(2, reducedPromise:expect())).to.equal("xp")
            expect(select(3, reducedPromise:expect())).to.equal(2000)
        end)
    end)

    describe("NonatomicChannelServer:getValue", function()
        it("should return a value that changes properly from server changes", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

            local serverBroadcast = ServerBroadcast.new(mockRemoteEvent, mockRemoteFunction)

            local ncServer = serverBroadcast:createNonatomicChannel("store", {
                xp = 0,
                inv = {},
            })

            expect(ncServer:getValue("xp")).to.equal(0)
            expect(ncServer:getValue("inv")[1]).to.equal(nil)

            ncServer:dispatch("setValue", "xp", 1000)
            ncServer:dispatch("insertValue", "inv", "gun")

            expect(ncServer:getValue("xp")).to.equal(1000)
            expect(ncServer:getValue("inv")[1]).to.equal("gun")
        end)
    end)

    describe("NonatomicChannelServer:getChangedSignal", function()
        it("should return a changed signal that is fired properly from server changes", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

            local serverBroadcast = ServerBroadcast.new(mockRemoteEvent, mockRemoteFunction)

            local ncServer = serverBroadcast:createNonatomicChannel("store", {
                xp = 0,
                inv = {},
            })

            local xpSignal = ncServer:getChangedSignal("xp")
            local invSignal = ncServer:getChangedSignal("inv")

            expect(xpSignal).to.be.a("table")
            expect(getmetatable(xpSignal)).to.equal(TrueSignal)

            expect(invSignal).to.be.a("table")
            expect(getmetatable(invSignal)).to.equal(TrueSignal)

            expect(ncServer:getValue("xp")).to.equal(0)
            expect(ncServer:getValue("inv")[1]).to.equal(nil)

            local xpPromise = xpSignal:promise()
            local invPromise = invSignal:promise()

            ncServer:dispatch("setValue", "xp", 1000)
            ncServer:dispatch("insertValue", "inv", "gun")

            expect(select(1, xpPromise:expect())).to.equal(1000)
            expect(select(2, xpPromise:expect())).to.equal(0)

            expect(select(1, invPromise:expect())[1]).to.equal("gun")
            expect(select(2, invPromise:expect())[1]).to.equal(nil)
        end)
    end)

    describe("NonatomicChannelServer:getReducedSignal", function()
        it("should return a reduced signal that is fired properly from server changes", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")
            
            local serverBroadcast = ServerBroadcast.new(mockRemoteEvent, mockRemoteFunction)

            local ncServer = serverBroadcast:createNonatomicChannel("store", {
                xp = 0,
                inv = {},
            })

            local xpSignal = ncServer:getReducedSignal("setValue", "xp")
            local invSignal = ncServer:getReducedSignal("insertValue", "inv")

            expect(xpSignal).to.be.a("table")
            expect(getmetatable(xpSignal)).to.equal(TrueSignal)

            expect(invSignal).to.be.a("table")
            expect(getmetatable(invSignal)).to.equal(TrueSignal)

            expect(ncServer:getValue("xp")).to.equal(0)
            expect(ncServer:getValue("inv")[1]).to.equal(nil)

            local xpPromise = xpSignal:promise()
            local invPromise = invSignal:promise()

            ncServer:dispatch("setValue", "xp", 1000)
            ncServer:dispatch("insertValue", "inv", "gun")

            expect(xpPromise:expect()).to.equal(1000)
            expect(invPromise:expect()).to.equal("gun")
        end)
    end)
end