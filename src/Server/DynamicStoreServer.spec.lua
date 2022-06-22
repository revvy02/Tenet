local MockNetwork = require(script.Parent.Parent.Parent.MockNetwork)
local Slick = require(script.Parent.Parent.Parent.Slick)

local ClientDynamicStream = require(script.Parent.Parent.Client.ClientDynamicStream)
local ServerDynamicStream = require(script.Parent.ServerDynamicStream)

return function()
    describe("DynamicStoreServer:getViewers", function()
        it("should return a list of players that the dynamic store is being streamed to", function()
            local server = MockNetwork.Server.new({"user0", "user1", "user2"})
            local user0, user1, user2 = server:getClient("user0"), server:getClient("user1"), server:getClient("user2")

            local serverDynamicStream = ServerDynamicStream.new({
                remoteEvent = server:createRemoteEvent("remoteEvent"),
            })

            local dynamicStoreServer = serverDynamicStream:create("store")

            dynamicStoreServer:stream(user0)
            dynamicStoreServer:stream(user1)
            
            local list = dynamicStoreServer:getViewers()

            expect(table.find(list, user0)).to.be.ok()
            expect(table.find(list, user1)).to.be.ok()
            expect(table.find(list, user2)).to.equal(nil)

            serverDynamicStream:destroy()
            server:destroy()
        end)
    end)

    describe("DynamicStoreServer:getSubscribers", function()
        it("should return a list of players that are subscribed to the passed key", function()
            local server = MockNetwork.Server.new({"user0", "user1", "user2"})
            local user0, user1, user2 = server:getClient("user0"), server:getClient("user1"), server:getClient("user2")

            local serverDynamicStream = ServerDynamicStream.new({
                remoteEvent = server:createRemoteEvent("remoteEvent"),
            })

            local dynamicStoreServer = serverDynamicStream:create("store", {
                xp = 0,
                inv = {},
            })

            dynamicStoreServer:subscribe("xp", user0)
            dynamicStoreServer:subscribe("inv", user0)
            dynamicStoreServer:subscribe("xp", user1)
            dynamicStoreServer:subscribe("inv", user2)
            
            local xpList = dynamicStoreServer:getSubscribers("xp")
            local invList = dynamicStoreServer:getSubscribers("inv")

            expect(table.find(xpList, user0)).to.be.ok()
            expect(table.find(xpList, user1)).to.be.ok()
            expect(table.find(xpList, user2)).to.never.be.ok()

            expect(table.find(invList, user0)).to.be.ok()
            expect(table.find(invList, user1)).to.never.be.ok()
            expect(table.find(invList, user2)).to.be.ok()

            serverDynamicStream:destroy()
            server:destroy()
        end)
    end)

    describe("DynamicStoreServer:isSubscribed", function()
        it("should return whether or not the passed player is subscribed to the key", function()
            local server = MockNetwork.Server.new({"user0", "user1", "user2"})
            local user0, user1, user2 = server:getClient("user0"), server:getClient("user1"), server:getClient("user2")

            local serverDynamicStream = ServerDynamicStream.new({
                remoteEvent = server:createRemoteEvent("remoteEvent"),
            })

            local dynamicStoreServer = serverDynamicStream:create("store", {
                xp = 0,
                inv = {},
            })

            dynamicStoreServer:subscribe("xp", user0)
            dynamicStoreServer:subscribe("inv", user0)
            dynamicStoreServer:subscribe("xp", user1)
            dynamicStoreServer:subscribe("inv", user2)

            expect(dynamicStoreServer:isSubscribed("xp", user0)).to.equal(true)
            expect(dynamicStoreServer:isSubscribed("inv", user0)).to.equal(true)

            expect(dynamicStoreServer:isSubscribed("xp", user1)).to.equal(true)
            expect(dynamicStoreServer:isSubscribed("inv", user1)).to.equal(false)

            expect(dynamicStoreServer:isSubscribed("xp", user2)).to.equal(false)
            expect(dynamicStoreServer:isSubscribed("inv", user2)).to.equal(true)

            serverDynamicStream:destroy()
            server:destroy()
        end)
    end)

    describe("DynamicStoreServer:isViewing", function()
        it("should return whether or not the dynamic store is being streamed to the passed player", function()
            local server = MockNetwork.Server.new({"user0", "user1", "user2"})
            local user0, user1, user2 = server:getClient("user0"), server:getClient("user1"), server:getClient("user2")

            local serverDynamicStream = ServerDynamicStream.new({
                remoteEvent = server:createRemoteEvent("remoteEvent"),
            })

            local dynamicStoreServer = serverDynamicStream:create("store")

            dynamicStoreServer:stream(user0)
            dynamicStoreServer:stream(user1)
            
            expect(dynamicStoreServer:isViewing(user0)).to.equal(true)
            expect(dynamicStoreServer:isViewing(user1)).to.equal(true)
            expect(dynamicStoreServer:isViewing(user2)).to.equal(false)

            serverDynamicStream:destroy()
            server:destroy()
        end)
    end)

    describe("DynamicStoreServer:subscribe", function()
        it("should load the key value on the client if they are viewing", function()
            local server = MockNetwork.Server.new({"user0", "user1", "user2"})
            local user0, user1, user2 = server:getClient("user0"), server:getClient("user1"), server:getClient("user2")

            local serverDynamicStream = ServerDynamicStream.new({
                remoteEvent = server:createRemoteEvent("remoteEvent"),
            })

            local cdsUser0 = ClientDynamicStream.new({
                remoteEvent = user0:getRemoteEvent("remoteEvent"),
            })

            local cdsUser1 = ClientDynamicStream.new({
                remoteEvent = user1:getRemoteEvent("remoteEvent"),
            })

            local cdsUser2 = ClientDynamicStream.new({
                remoteEvent = user2:getRemoteEvent("remoteEvent"),
            })

            local dynamicStoreServer = serverDynamicStream:create("store", {
                xp = 0,
                inv = {},
            })

            dynamicStoreServer:subscribe("xp", user0)
            dynamicStoreServer:subscribe("inv", user0)
            dynamicStoreServer:subscribe("xp", user1)
            dynamicStoreServer:subscribe("xp", user2)

            local dscUser0 = cdsUser0:get("store")
            local dscUser1 = cdsUser1:get("store")
            local dscUser2 = cdsUser2:get("store")

            expect(dynamicStoreClient:getValue("xp")).to.equal(nil)

            dynamicStoreServer:subscribe("xp", "user")

            expect(dynamicStoreClient:getValue("xp")).to.equal(0)

            mockRemoteEvent:destroy()
            clientDynamicStream:destroy()
            serverDynamicStream:destroy()
        end)

        it("should fire the loaded signal on the client if they are viewing", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")

            local serverDynamicStream = ServerDynamicStream.new({
                remoteEvent = mockRemoteEvent,
            })

            local clientDynamicStream = ClientDynamicStream.new({
                remoteEvent = mockRemoteEvent,
            })

            local dynamicStoreServer = serverDynamicStream:create("store", {
                xp = 0,
                inv = {},
            })

            dynamicStoreServer:stream("user")

            local dynamicStoreClient = clientDynamicStream:get("store")
            local passed = false

            dynamicStoreClient.loaded:connect(function(key)
                if key == "xp" then
                    passed = true
                end
            end)

            dynamicStoreServer:subscribe("xp", "user")

            expect(passed).to.equal(true)
            expect(dynamicStoreClient:getValue("xp")).to.equal(0)
            
            mockRemoteEvent:destroy()
            clientDynamicStream:destroy()
            serverDynamicStream:destroy()
        end)

        it("should throw if the client isn't viewing the store", function()

        end)
    end)

    describe("DynamicStoreServer:unsubscribe", function()
        it("should set the key value on the client to nil if they are viewing", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")

            local serverDynamicStream = ServerDynamicStream.new({
                remoteEvent = mockRemoteEvent,
            })

            local clientDynamicStream = ClientDynamicStream.new({
                remoteEvent = mockRemoteEvent,
            })

            local dynamicStoreServer = serverDynamicStream:create("store", {
                xp = 0,
                inv = {},
            })

            dynamicStoreServer:stream("user")
            dynamicStoreServer:subscribe("xp", "user")

            local dynamicStoreClient = clientDynamicStream:get("store")

            expect(dynamicStoreClient:getValue("xp")).to.equal(0)

            dynamicStoreServer:unsubscribe("xp", "user")

            expect(dynamicStoreClient:getValue("xp")).to.equal(nil)

            mockRemoteEvent:destroy()
            clientDynamicStream:destroy()
            serverDynamicStream:destroy()
        end)

        it("should fire the unloaded signal on the client if they are viewing", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")

            local serverDynamicStream = ServerDynamicStream.new({
                remoteEvent = mockRemoteEvent,
            })

            local clientDynamicStream = ClientDynamicStream.new({
                remoteEvent = mockRemoteEvent,
            })

            local dynamicStoreServer = serverDynamicStream:create("store", {
                xp = 0,
                inv = {},
            })

            dynamicStoreServer:stream("user")
            dynamicStoreServer:subscribe("xp", "user")

            local dynamicStoreClient = clientDynamicStream:get("store")
            local passed = false

            dynamicStoreClient.unloaded:connect(function(key)
                if key == "xp" then
                    passed = true
                end
            end)

            dynamicStoreServer:unsubscribe("xp", "user")

            expect(passed).to.equal(true)
            expect(dynamicStoreClient:getValue("xp")).to.equal(nil)

            mockRemoteEvent:destroy()
            clientDynamicStream:destroy()
            serverDynamicStream:destroy()
        end)
    end)



    describe("DynamicStoreServer:stream", function()
        it("should load the dynamic store on the client with an empty state", function()

        end)

        it("should fire the streamed signal on the client", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")

            local serverDynamicStream = ServerDynamicStream.new({
                remoteEvent = mockRemoteEvent,
            })

            local clientDynamicStream = ClientDynamicStream.new({
                remoteEvent = mockRemoteEvent,
            })

            local dynamicStoreServer = serverDynamicStream:create("store", {
                xp = 1000,
                inv = {"gun"},
            })

            local passed = false

            clientDynamicStream.streamed:connect(function(owner)
                if owner == "store" then
                    passed = true
                end
            end)

            dynamicStoreServer:stream("user")
            
            expect(passed).to.equal(true)

            clientDynamicStream:destroy()
            serverDynamicStream:destroy()
            mockRemoteEvent:destroy()
        end)
    end)

    describe("DynamicStoreServer:unstream", function()

    end)





    describe("DynamicStoreServer:dispatch", function()
        it("should properly update the server", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")

            local serverDynamicStream = ServerDynamicStream.new({
                remoteEvent = mockRemoteEvent,
            })

            local dynamicStoreServer = serverDynamicStream:create("store", {
                xp = 1000,
                inv = {"gun"},
            })

            local changedPromise = dynamicStoreServer.changed:promise()
            local reducedPromise = dynamicStoreServer.reduced:promise()

            dynamicStoreServer:dispatch("xp", "setValue", 2000)

            expect(dynamicStoreServer:getValue("xp")).to.equal(2000)

            expect(select(1, changedPromise:expect())).to.equal("xp")
            expect(select(2, changedPromise:expect()).xp).to.equal(2000)
            expect(select(3, changedPromise:expect()).xp).to.equal(1000)

            expect(select(1, reducedPromise:expect())).to.equal("xp")
            expect(select(2, reducedPromise:expect())).to.equal("setValue")
            expect(select(3, reducedPromise:expect())).to.equal(2000)

            serverDynamicStream:destroy()
            mockRemoteEvent:destroy()
        end)

        it("should properly update clients subscribed to the key", function()
            local server = MockNetwork.Server.new({"user0", "user1", "user2"})
            local user0, user1, user2 = server:getClient("user0"), server:getClient("user1"), server:getClient("user2")

            local mockRemoteEvent = server:createRemoteEvent("remoteEvent")

            local serverDynamicStream = ServerDynamicStream.new({
                remoteEvent = mockRemoteEvent,
            })

            local cdsUser0 = ClientDynamicStream.new({
                remoteEvent = user0:getRemoteEvent("remoteEvent"),
            })

            local cdsUser1 = ClientDynamicStream.new({
                remoteEvent = user1:getRemoteEvent("remoteEvent"),
            })

            local cdsUser2 = ClientDynamicStream.new({
                remoteEvent = user2:getRemoteEvent("remoteEvent"),
            })

            local dynamicStoreServer = serverDynamicStream:create("store", {
                xp = 1000,
                inv = {"gun"},
            })

            dynamicStoreServer:subscribe("xp", user0)
            dynamicStoreServer:subscribe("inv", user0)

            dynamicStoreServer:subscribe("xp", user1)

            dynamicStoreServer:subscribe("inv", user2)

            local changedPromise = dynamicStoreServer.changed:promise()
            local reducedPromise = dynamicStoreServer.reduced:promise()

            dynamicStoreServer:dispatch("xp", "setValue", 2000)

            expect(dynamicStoreServer:getValue("xp")).to.equal(2000)

            expect(select(1, changedPromise:expect())).to.equal("xp")
            expect(select(2, changedPromise:expect()).xp).to.equal(2000)
            expect(select(3, changedPromise:expect()).xp).to.equal(1000)

            expect(select(1, reducedPromise:expect())).to.equal("xp")
            expect(select(2, reducedPromise:expect())).to.equal("setValue")
            expect(select(3, reducedPromise:expect())).to.equal(2000)

            serverDynamicStream:destroy()
            mockRemoteEvent:destroy()
        end)

        it("should not update clients not subscribed to the key", function()

        end)
    end)

    describe("DynamicStoreServer:getValue", function()

    end)

    describe("DynamicStoreServer:getChangedSignal", function()

    end)

    describe("DynamicStoreServer:getReducedSignal", function()

    end)

    describe("DynamicStoreServer:destroy", function()

    end)
end