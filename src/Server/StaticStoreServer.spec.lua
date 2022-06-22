local MockNetwork = require(script.Parent.Parent.Parent.MockNetwork)
local TrueSignal = require(script.Parent.Parent.Parent.TrueSignal)
local Cleaner = require(script.Parent.Parent.Parent.Cleaner)

local ClientStream = require(script.Parent.Parent.Client.ClientStream)
local ServerStream = require(script.Parent.ServerStream)

return function()
    describe("StaticStoreServer:getViewers", function()
        it("should return a list of players that the static store is being streamed to", function()
            local cleaner = Cleaner.new()

            local server = cleaner:give(MockNetwork.Server.new({"user0", "user1", "user2"}))
            local clients = server:getClientsMapped()

            local serverStream = cleaner:give(ServerStream.new({
                remoteEvent = server:createRemoteEvent("remoteEvent"),
            }))

            local ssServer = serverStream:create("store")

            ssServer:stream(clients.user0)
            ssServer:stream(clients.user1)
            
            local list = ssServer:getViewers()

            expect(table.find(list, clients.user0)).to.be.ok()
            expect(table.find(list, clients.user1)).to.be.ok()
            expect(table.find(list, clients.user2)).to.never.be.ok()

            serverStream:destroy()
            server:destroy()
        end)
    end)

    describe("StaticStoreServer:isViewing", function()
        it("should return whether or not the static store is being streamed to the passed player", function()
            local server, clients = MockNetwork.Server.new("user1", "user2", "user3")

            local serverStream = ServerStream.new({
                remoteEvent = server:createRemoteEvent("remoteEvent"),
            })

            local ssServer = serverStream:create("store")

            ssServer:stream(user1)
            ssServer:stream(user2)
            
            expect(ssServer:isViewing(user1)).to.equal(true)
            expect(ssServer:isViewing(user2)).to.equal(true)
            expect(ssServer:isViewing(user3)).to.equal(false)

            serverStream:destroy()
            server:destroy()
        end)
    end)

    describe("StaticStoreServer:stream", function()
        it("should create the static store on the client with initial state", function()
            local server, user1, user2 = MockNetwork.Server.new("user1", "user2", "user3")

            local serverStream = ServerStream.new({
                remoteEvent = server:createRemoteEvent("remoteEvent"),
            })

            local clientStream = ClientStream.new({
                remoteEvent = mockRemoteEvent,
            })

            local ssServer = serverStream:create("store", {
                xp = 1000,
                inv = {"gun"},
            })

            ssServer:stream("user")

            local ssClient = clientStream:get("store")

            expect(ssClient).to.be.ok()
            expect(ssClient:getValue("xp")).to.equal(1000)
            expect(ssClient:getValue("inv")[1]).to.equal("gun")
            
            clientStream:destroy()
            serverStream:destroy()
            mockRemoteEvent:destroy()
        end)

        it("should fire the streamed signal on the client", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")

            local serverStream = ServerStream.new({
                remoteEvent = mockRemoteEvent,
            })

            local clientStream = ClientStream.new({
                remoteEvent = mockRemoteEvent,
            })

            local ssServer = serverStream:create("store", {
                xp = 1000,
                inv = {"gun"},
            })

            local passed = false

            clientStream.streamed:connect(function(owner)
                if owner == "store" then
                    passed = true
                end
            end)

            ssServer:stream("user")
            
            expect(passed).to.equal(true)

            clientStream:destroy()
            serverStream:destroy()
            mockRemoteEvent:destroy()
        end)
    end)

    describe("StaticStoreServer:unstream", function()
        it("should destroy the static store on the client", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")

            local serverStream = ServerStream.new({
                remoteEvent = mockRemoteEvent,
            })

            local clientStream = ClientStream.new({
                remoteEvent = mockRemoteEvent,
            })

            local ssServer = serverStream:create("store", {
                xp = 1000,
                inv = {"gun"},
            })

            ssServer:stream("user")

            local ssClient = clientStream:get("store")

            expect(ssClient).to.be.ok()

            ssServer:unstream("user")

            expect(ssClient.destroyed).to.equal(true)

            clientStream:destroy()
            serverStream:destroy()
            mockRemoteEvent:destroy()
        end)

        it("should fire the unstreaming signal on the client", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")

            local serverStream = ServerStream.new({
                remoteEvent = mockRemoteEvent,
            })

            local clientStream = ClientStream.new({
                remoteEvent = mockRemoteEvent,
            })

            local ssServer = serverStream:create("store", {
                xp = 1000,
                inv = {"gun"},
            })

            ssServer:stream("user")

            local passed = false

            clientStream.unstreaming:connect(function(owner)
                if owner == "store" then
                    passed = true
                end
            end)

            ssServer:unstream("user")
            
            expect(passed).to.equal(true)

            clientStream:destroy()
            serverStream:destroy()
            mockRemoteEvent:destroy()
        end)
    end)

    describe("StaticStoreServer:dispatch", function()
        it("should properly update the server", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")

            local serverStream = ServerStream.new({
                remoteEvent = mockRemoteEvent,
            })

            local ssServer = serverStream:create("store", {
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

            serverStream:destroy()
            mockRemoteEvent:destroy()
        end)

        it("should properly update viewing clients", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")

            local serverStream = ServerStream.new({
                remoteEvent = mockRemoteEvent,
            })

            local clientStream = ClientStream.new({
                remoteEvent = mockRemoteEvent,
            })

            local ssServer = serverStream:create("store", {
                xp = 1000,
                inv = {"gun"},
            })

            ssServer:stream("user")

            local ssClient = clientStream:get("store")

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

            clientStream:destroy()
            serverStream:destroy()
            mockRemoteEvent:destroy()
        end)
    end)

    describe("StaticStoreServer:getValue", function()
        it("should return a value that changes properly from server changes", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")

            local serverStream = ServerStream.new({
                remoteEvent = mockRemoteEvent,
            })

            local ssServer = serverStream:create("store", {
                xp = 0,
                inv = {},
            })

            expect(ssServer:getValue("xp")).to.equal(0)
            expect(ssServer:getValue("inv")[1]).to.equal(nil)

            ssServer:dispatch("xp", "setValue", 1000)
            ssServer:dispatch("inv", "insertValue", "gun")

            expect(ssServer:getValue("xp")).to.equal(1000)
            expect(ssServer:getValue("inv")[1]).to.equal("gun")

            serverStream:destroy()
            mockRemoteEvent:destroy()
        end)
    end)

    describe("StaticStoreServer:getChangedSignal", function()
        it("should return a changed signal that is fired properly from server changes", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")

            local serverStream = ServerStream.new({
                remoteEvent = mockRemoteEvent,
            })

            local ssServer = serverStream:create("store", {
                xp = 0,
                inv = {},
            })

            ssServer:stream("user")

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

            serverStream:destroy()
            mockRemoteEvent:destroy()
        end)
    end)

    describe("StaticStoreServer:getReducedSignal", function()
        it("should return a reduced signal that is fired properly from server changes", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")

            local serverStream = ServerStream.new({
                remoteEvent = mockRemoteEvent,
            })

            local ssServer = serverStream:create("store", {
                xp = 0,
                inv = {},
            })

            ssServer:stream("user")

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

            serverStream:destroy()
            mockRemoteEvent:destroy()
        end)
    end)
end