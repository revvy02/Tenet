local MockNetwork = require(script.Parent.Parent.Parent.MockNetwork)
local Promise = require(script.Parent.Parent.Parent.Promise)
local TrueSignal = require(script.Parent.Parent.Parent.TrueSignal)
local Cleaner = require(script.Parent.Parent.Parent.Cleaner)

local ClientChannel = require(script.Parent.Parent.Client.ClientChannel)
local ServerChannel = require(script.Parent.ServerChannel)

return function()
    local function mapClientChannels(id, client)
        return id, ClientChannel.new(client:getRemoteEvent("remoteEvent"), client:getRemoteFunction("remoteFunction"))
    end

    describe("StaticStoreServer:getSubscribers", function()
        it("should return a list of players that are viewing the static store", function()
            local server = MockNetwork.Server.new({"user1", "user2", "user3"})
            local clients = server:mapClients()

            local serverChannel = ServerChannel.new(server:createRemoteEvent("remoteEvent"), server:createRemoteFunction("remoteFunction"))

            local ssServer = serverChannel:create("store")

            ssServer:subscribe(clients.user1)
            ssServer:subscribe(clients.user2)
            
            local list = ssServer:getSubscribers()

            expect(table.find(list, clients.user1)).to.be.ok()
            expect(table.find(list, clients.user2)).to.be.ok()
            expect(table.find(list, clients.user3)).to.never.be.ok()
        end)
    end)

    describe("StaticStoreServer:isViewing", function()
        it("should return whether or not the player is viewing the static store", function()
            local server = MockNetwork.Server.new({"user1", "user2", "user3"})
            local clients = server:mapClients()

            local serverChannel = ServerChannel.new(server:createRemoteEvent("remoteEvent"), server:createRemoteFunction("remoteFunction"))

            local ssServer = serverChannel:create("store")

            ssServer:subscribe(clients.user1)
            ssServer:subscribe(clients.user2)
            
            expect(ssServer:isSubscribed(clients.user1)).to.equal(true)
            expect(ssServer:isSubscribed(clients.user2)).to.equal(true)
            expect(ssServer:isSubscribed(clients.user3)).to.equal(false)
        end)
    end)

    describe("StaticStoreServer:subscribe", function()
        it("should create the static store on the client with the current server state", function()
            local server = MockNetwork.Server.new({"user1", "user2"})
            local clients = server:mapClients()

            local serverChannel = ServerChannel.new(server:createRemoteEvent("remoteEvent"), server:createRemoteFunction("remoteFunction"))
            local clientChannels = server:mapClients(mapClientChannels)

            local ssServer = serverChannel:create("store", {
                xp = 1000,
                inv = {"gun"},
            })

            ssServer:subscribe(clients.user1)

            local ssClients = {
                user1 = clientChannels.user1:get("store"),
                user2 = clientChannels.user2:get("store"),
            }

            expect(ssClients.user1).to.be.ok()
            expect(ssClients.user1:getValue("xp")).to.equal(1000)
            expect(ssClients.user1:getValue("inv")[1]).to.equal("gun")
            
            expect(ssClients.user2).to.never.be.ok()
        end)

        it("should fire the subscribed signal on the client", function()
            local server = MockNetwork.Server.new({"user1", "user2"})
            local clients = server:mapClients()

            local serverChannel = ServerChannel.new(server:createRemoteEvent("remoteEvent"), server:createRemoteFunction("remoteFunction"))
            local clientChannels = server:mapClients(mapClientChannels)

            local ssServer = serverChannel:create("store", {
                xp = 1000,
                inv = {"gun"},
            })

            local user1Promise = clientChannels.user1.subscribed:promise()
            local user2Promise = clientChannels.user2.subscribed:promise()

            expect(user1Promise:getStatus()).to.equal(Promise.Status.Started)
            expect(user2Promise:getStatus()).to.equal(Promise.Status.Started)

            ssServer:subscribe(clients.user1)
            
            expect(user1Promise:getStatus()).to.equal(Promise.Status.Resolved)
            expect(user2Promise:getStatus()).to.equal(Promise.Status.Started)

            expect(select(1, user1Promise:expect())).to.equal("store")

            ssServer:subscribe(clients.user2)

            expect(user2Promise:getStatus()).to.equal(Promise.Status.Resolved)
            expect(select(1, user2Promise:expect())).to.equal("store")
        end)
    end)

    describe("StaticStoreServer:unsubscribe", function()
        it("should destroy the static store on the client", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

            local serverChannel = ServerChannel.new(mockRemoteEvent, mockRemoteFunction)
            local clientChannel = ClientChannel.new(mockRemoteEvent, mockRemoteFunction)

            local ssServer = serverChannel:create("store", {
                xp = 1000,
                inv = {"gun"},
            })

            ssServer:subscribe("user")

            local ssClient = clientChannel:get("store")

            expect(ssClient).to.be.ok()

            ssServer:unsubscribe("user")

            expect(ssClient.destroyed).to.equal(true)
        end)

        it("should fire the unsubscribed signal on the client", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

            local serverChannel = ServerChannel.new(mockRemoteEvent, mockRemoteFunction)
            local clientChannel = ClientChannel.new(mockRemoteEvent, mockRemoteFunction)

            local ssServer = serverChannel:create("store", {
                xp = 1000,
                inv = {"gun"},
            })

            ssServer:subscribe("user")

            local passed = false

            clientChannel.unsubscribed:connect(function(owner)
                if owner == "store" then
                    passed = true
                end
            end)

            ssServer:unsubscribe("user")
            
            expect(passed).to.equal(true)
        end)
    end)

    describe("StaticStoreServer:dispatch", function()
        it("should properly update the server", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

            local serverChannel = ServerChannel.new(mockRemoteEvent, mockRemoteFunction)

            local ssServer = serverChannel:create("store", {
                xp = 1000,
                inv = {"gun"},
            })

            local changedPromise = ssServer.changed:promise()
            local reducedPromise = ssServer.reduced:promise()

            ssServer:dispatch("xp", "setValue", 2000)

            expect(ssServer:getValue("xp")).to.equal(2000)

            expect(select(1, changedPromise:expect())).to.equal("xp")
            expect(select(2, changedPromise:expect()).xp).to.equal(2000)
            expect(select(3, changedPromise:expect()).xp).to.equal(1000)

            expect(select(1, reducedPromise:expect())).to.equal("xp")
            expect(select(2, reducedPromise:expect())).to.equal("setValue")
            expect(select(3, reducedPromise:expect())).to.equal(2000)
        end)

        it("should properly update viewing clients", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

            local serverChannel = ServerChannel.new(mockRemoteEvent, mockRemoteFunction)
            local clientChannel = ClientChannel.new(mockRemoteEvent, mockRemoteFunction)

            local ssServer = serverChannel:create("store", {
                xp = 1000,
                inv = {"gun"},
            })

            ssServer:subscribe("user")

            local ssClient = clientChannel:get("store")

            local changedPromise = ssClient.changed:promise()
            local reducedPromise = ssClient.reduced:promise()

            ssServer:dispatch("xp", "setValue", 2000)

            expect(ssServer:getValue("xp")).to.equal(2000)

            expect(select(1, changedPromise:expect())).to.equal("xp")
            expect(select(2, changedPromise:expect()).xp).to.equal(2000)
            expect(select(3, changedPromise:expect()).xp).to.equal(1000)

            expect(select(1, reducedPromise:expect())).to.equal("xp")
            expect(select(2, reducedPromise:expect())).to.equal("setValue")
            expect(select(3, reducedPromise:expect())).to.equal(2000)
        end)
    end)

    describe("StaticStoreServer:getValue", function()
        it("should return a value that changes properly from server changes", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

            local serverChannel = ServerChannel.new(mockRemoteEvent, mockRemoteFunction)

            local ssServer = serverChannel:create("store", {
                xp = 0,
                inv = {},
            })

            expect(ssServer:getValue("xp")).to.equal(0)
            expect(ssServer:getValue("inv")[1]).to.equal(nil)

            ssServer:dispatch("xp", "setValue", 1000)
            ssServer:dispatch("inv", "insertValue", "gun")

            expect(ssServer:getValue("xp")).to.equal(1000)
            expect(ssServer:getValue("inv")[1]).to.equal("gun")
        end)
    end)

    describe("StaticStoreServer:getChangedSignal", function()
        it("should return a changed signal that is fired properly from server changes", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

            local serverChannel = ServerChannel.new(mockRemoteEvent, mockRemoteFunction)

            local ssServer = serverChannel:create("store", {
                xp = 0,
                inv = {},
            })

            ssServer:subscribe("user")

            local xpSignal = ssServer:getChangedSignal("xp")
            local invSignal = ssServer:getChangedSignal("inv")

            expect(xpSignal).to.be.a("table")
            expect(getmetatable(xpSignal)).to.equal(TrueSignal)

            expect(invSignal).to.be.a("table")
            expect(getmetatable(invSignal)).to.equal(TrueSignal)

            expect(ssServer:getValue("xp")).to.equal(0)
            expect(ssServer:getValue("inv")[1]).to.equal(nil)

            local xpPromise = xpSignal:promise()
            local invPromise = invSignal:promise()

            ssServer:dispatch("xp", "setValue", 1000)
            ssServer:dispatch("inv", "insertValue", "gun")

            expect(select(1, xpPromise:expect())).to.equal(1000)
            expect(select(2, xpPromise:expect())).to.equal(0)

            expect(select(1, invPromise:expect())[1]).to.equal("gun")
            expect(select(2, invPromise:expect())[1]).to.equal(nil)
        end)
    end)

    describe("StaticStoreServer:getReducedSignal", function()
        it("should return a reduced signal that is fired properly from server changes", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")
            
            local serverChannel = ServerChannel.new(mockRemoteEvent, mockRemoteFunction)

            local ssServer = serverChannel:create("store", {
                xp = 0,
                inv = {},
            })

            ssServer:subscribe("user")

            local xpSignal = ssServer:getReducedSignal("xp", "setValue")
            local invSignal = ssServer:getReducedSignal("inv", "insertValue")

            expect(xpSignal).to.be.a("table")
            expect(getmetatable(xpSignal)).to.equal(TrueSignal)

            expect(invSignal).to.be.a("table")
            expect(getmetatable(invSignal)).to.equal(TrueSignal)

            expect(ssServer:getValue("xp")).to.equal(0)
            expect(ssServer:getValue("inv")[1]).to.equal(nil)

            local xpPromise = xpSignal:promise()
            local invPromise = invSignal:promise()

            ssServer:dispatch("xp", "setValue", 1000)
            ssServer:dispatch("inv", "insertValue", "gun")

            expect(xpPromise:expect()).to.equal(1000)
            expect(invPromise:expect()).to.equal("gun")
        end)
    end)
end