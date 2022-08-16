local MockNetwork = require(script.Parent.Parent.Parent.MockNetwork)
local Promise = require(script.Parent.Parent.Parent.Promise)
local TrueSignal = require(script.Parent.Parent.Parent.TrueSignal)

local ClientBroadcast= require(script.Parent.ClientBroadcast)
local ServerBroadcast = require(script.Parent.Parent.Server.ServerBroadcast)

return function()
    describe("NonatomicChannelClient:getValue", function()
        it("should return a value that changes properly from server changes", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")

            local ServerBroadcast = ServerBroadcast.new(mockRemoteEvent, true)
            local ClientBroadcast = ClientBroadcast.new(mockRemoteEvent)

            local dsServer = ServerBroadcast:create("store", {
                xp = 0,
                inv = {},
            })

            dsServer:subscribe("user")

            dsServer:Stream("xp", "user")
            dsServer:Stream("inv", "user")
            
            local dsClient = ClientBroadcast:get("store")

            expect(dsClient:getValue("xp")).to.equal(0)
            expect(dsClient:getValue("inv")[1]).to.equal(nil)

            dsServer:dispatch("xp", "setValue", 1000)
            dsServer:dispatch("inv", "insertValue", "gun")

            expect(dsClient:getValue("xp")).to.equal(1000)
            expect(dsClient:getValue("inv")[1]).to.equal("gun")
        end)
    end)

    describe("NonatomicChannelClient:getChangedSignal", function()
        it("should return a changed signal that is fired properly from server changes", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")

            local ServerBroadcast = ServerBroadcast.new(mockRemoteEvent, true)
            local ClientBroadcast = ClientBroadcast.new(mockRemoteEvent)

            local sdStore = ServerBroadcast:create("store", {
                xp = 0,
                inv = {},
            })

            sdStore:view("user")

            sdStore:subscribe("xp", "user")
            sdStore:subscribe("inv", "user")

            local cdStore = ClientBroadcast:get("store")

            local xpSignal = cdStore:getChangedSignal("xp")
            local invSignal = cdStore:getChangedSignal("inv")

            expect(xpSignal).to.be.a("table")
            expect(getmetatable(xpSignal)).to.equal(TrueSignal)

            expect(invSignal).to.be.a("table")
            expect(getmetatable(invSignal)).to.equal(TrueSignal)

            expect(cdStore:getValue("xp")).to.equal(0)
            expect(cdStore:getValue("inv")[1]).to.equal(nil)

            local xpPromise = xpSignal:promise()
            local invPromise = invSignal:promise()

            sdStore:dispatch("xp", "setValue", 1000)
            sdStore:dispatch("inv", "insertValue", "gun")

            expect(select(1, xpPromise:expect())).to.equal(1000)
            expect(select(2, xpPromise:expect())).to.equal(0)

            expect(select(1, invPromise:expect())[1]).to.equal("gun")
            expect(select(2, invPromise:expect())[1]).to.equal(nil)

            ClientBroadcast:destroy()
            ServerBroadcast:destroy()
            mockRemoteEvent:destroy()
        end)
    end)

    describe("NonatomicChannelClient:getReducedSignal", function()
        it("should return a reduced signal that is fired properly from server changes", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")

            local ServerBroadcast = ServerBroadcast.new(mockRemoteEvent, true)
            local ClientBroadcast = ClientBroadcast.new(mockRemoteEvent)

            local sdStore = ServerBroadcast:create("store", {
                xp = 0,
                inv = {},
            })

            sdStore:subscribe("user")

            sdStore:view("xp", "user")
            sdStore:subscribe("inv", "user")

            local clientDynamicStore = ClientBroadcast:get("store")

            local xpSignal = clientDynamicStore:getReducedSignal("xp", "setValue")
            local invSignal = clientDynamicStore:getReducedSignal("inv", "insertValue")

            expect(xpSignal).to.be.a("table")
            expect(getmetatable(xpSignal)).to.equal(TrueSignal)

            expect(invSignal).to.be.a("table")
            expect(getmetatable(invSignal)).to.equal(TrueSignal)

            expect(clientDynamicStore:getValue("xp")).to.equal(0)
            expect(clientDynamicStore:getValue("inv")[1]).to.equal(nil)

            local xpPromise = xpSignal:promise()
            local invPromise = invSignal:promise()

            sdStore:dispatch("xp", "setValue", 1000)
            sdStore:dispatch("inv", "insertValue", "gun")

            expect(xpPromise:expect()).to.equal(1000)
            expect(invPromise:expect()).to.equal("gun")

            ClientBroadcast:destroy()
            ServerBroadcast:destroy()
            mockRemoteEvent:destroy()
        end)
    end)

    describe("NonatomicChannelClient:viewedAsync", function()
        it("should return a promise that resolves when the key is streamed in", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")

            local ServerBroadcast = ServerBroadcast.new(mockRemoteEvent, true)
            local ClientBroadcast = ClientBroadcast.new(mockRemoteEvent)

            local sdStore = ServerBroadcast:create("store", {
                xp = 0,
                inv = {},
            })

            sdStore:subscribe("user")

            local cdStore = ClientBroadcast:get("store")

            local promise = cdStore:loadedAsync("xp")

            expect(promise:getStatus()).to.equal(Promise.Status.Started)
            expect(cdStore:getValue("xp")).to.equal(nil)
            expect(cdStore:getValue("inv")).to.equal(nil)

            sdStore:subscribe("xp", "user")

            expect(promise:getStatus()).to.equal(Promise.Status.Resolved)
            expect(cdStore:getValue("xp")).to.equal(0)
            expect(cdStore:getValue("inv")).to.equal(nil)

            ClientBroadcast:destroy()
            ServerBroadcast:destroy()
            mockRemoteEvent:destroy()
        end)
    end)
end