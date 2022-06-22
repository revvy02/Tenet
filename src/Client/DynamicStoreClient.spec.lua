local MockNetwork = require(script.Parent.Parent.Parent.MockNetwork)
local Promise = require(script.Parent.Parent.Parent.Promise)
local TrueSignal = require(script.Parent.Parent.Parent.TrueSignal)

local ClientStream = require(script.Parent.ClientStream)
local ServerStream = require(script.Parent.Parent.Server.ServerStream)

return function()
    describe("DynamicStoreClient:getValue", function()
        it("should return a value that changes properly from server changes", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")

            local serverStream = ServerStream.new({
                remoteEvent = mockRemoteEvent,
            }, true)

            local clientStream = ClientStream.new({
                remoteEvent = mockRemoteEvent,
            })

            local sdStore = serverStream:create("store", {
                xp = 0,
                inv = {},
            })

            sdStore:stream("user")

            sdStore:subscribe("xp", "user")
            sdStore:subscribe("inv", "user")
            
            local cdStore = clientStream:get("store")

            expect(cdStore:getValue("xp")).to.equal(0)
            expect(cdStore:getValue("inv")[1]).to.equal(nil)

            sdStore:dispatch("xp", "setValue", 1000)
            sdStore:dispatch("inv", "insertValue", "gun")

            expect(cdStore:getValue("xp")).to.equal(1000)
            expect(cdStore:getValue("inv")[1]).to.equal("gun")

            clientStream:destroy()
            serverStream:destroy()
            mockRemoteEvent:destroy()
        end)
    end)

    describe("DynamicStoreClient:getChangedSignal", function()
        it("should return a changed signal that is fired properly from server changes", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")

            local serverStream = ServerStream.new({
                remoteEvent = mockRemoteEvent,
            }, true)

            local clientStream = ClientStream.new({
                remoteEvent = mockRemoteEvent,
            })

            local sdStore = serverStream:create("store", {
                xp = 0,
                inv = {},
            })

            sdStore:stream("user")

            sdStore:subscribe("xp", "user")
            sdStore:subscribe("inv", "user")

            local cdStore = clientStream:get("store")

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

            clientStream:destroy()
            serverStream:destroy()
            mockRemoteEvent:destroy()
        end)
    end)

    describe("DynamicStoreClient:getReducedSignal", function()
        it("should return a reduced signal that is fired properly from server changes", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")

            local serverStream = ServerStream.new({
                remoteEvent = mockRemoteEvent,
            }, true)

            local clientStream = ClientStream.new({
                remoteEvent = mockRemoteEvent,
            })

            local sdStore = serverStream:create("store", {
                xp = 0,
                inv = {},
            })

            sdStore:stream("user")

            sdStore:subscribe("xp", "user")
            sdStore:subscribe("inv", "user")

            local clientDynamicStore = clientStream:get("store")

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

            clientStream:destroy()
            serverStream:destroy()
            mockRemoteEvent:destroy()
        end)
    end)

    describe("DynamicStoreClient:loadedAsync", function()
        it("should return a promise that resolves when a key is loaded", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")

            local serverStream = ServerStream.new({
                remoteEvent = mockRemoteEvent,
            }, true)

            local clientStream = ClientStream.new({
                remoteEvent = mockRemoteEvent,
            })

            local sdStore = serverStream:create("store", {
                xp = 0,
                inv = {},
            })

            sdStore:stream("user")

            local cdStore = clientStream:get("store")

            local promise = cdStore:loadedAsync("xp")

            expect(promise:getStatus()).to.equal(Promise.Status.Started)
            expect(cdStore:getValue("xp")).to.equal(nil)
            expect(cdStore:getValue("inv")).to.equal(nil)

            sdStore:subscribe("xp", "user")

            expect(promise:getStatus()).to.equal(Promise.Status.Resolved)
            expect(cdStore:getValue("xp")).to.equal(0)
            expect(cdStore:getValue("inv")).to.equal(nil)

            clientStream:destroy()
            serverStream:destroy()
            mockRemoteEvent:destroy()
        end)
    end)
end