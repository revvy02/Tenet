local MockNetwork = require(script.Parent.Parent.Parent.MockNetwork)
local Slick = require(script.Parent.Parent.Parent.Slick)

local ClientStaticStream = require(script.Parent.Parent.Client.ClientStaticStream)
local ServerStaticStream = require(script.Parent.ServerStaticStream)

return function()
    describe("StaticStoreServer:getViewers", function()
        it("should return a list of players that the static store is being streamed to", function()
            local server = MockNetwork.Server.new({"user0", "user1", "user2"})

            local serverStaticStream = ServerStaticStream.new({
                remoteEvent = server:createRemoteEvent("remoteEvent"),
            })

            local staticStoreServer = serverStaticStream:create("store")

            staticStoreServer:stream(server:getClient("user0"))
            staticStoreServer:stream(server:getClient("user1"))
            
            local list = staticStoreServer:getViewers()

            expect(table.find(list, server:getClient("user0"))).to.be.ok()
            expect(table.find(list, server:getClient("user1"))).to.be.ok()
            expect(table.find(list, server:getClient("user2"))).to.never.be.ok()

            serverStaticStream:destroy()
            server:destroy()
        end)
    end)

    describe("StaticStoreServer:isViewing", function()
        it("should return whether or not the static store is being streamed to the passed player", function()
            local server = MockNetwork.Server.new({"user0", "user1", "user2"})

            local serverStaticStream = ServerStaticStream.new({
                remoteEvent = server:createRemoteEvent("remoteEvent"),
            })

            local staticStoreServer = serverStaticStream:create("store")

            staticStoreServer:stream(server:getClient("user0"))
            staticStoreServer:stream(server:getClient("user1"))
            
            expect(staticStoreServer:isViewing(server:getClient("user0"))).to.equal(true)
            expect(staticStoreServer:isViewing(server:getClient("user1"))).to.equal(true)
            expect(staticStoreServer:isViewing(server:getClient("user2"))).to.equal(false)

            serverStaticStream:destroy()
            server:destroy()
        end)
    end)

    describe("StaticStoreServer:stream", function()
        it("should properly stream the static store to the client", function()
            local server = MockNetwork.Server.new({"user0", "user1", "user2"})

            local serverStaticStream = ServerStaticStream.new({
                remoteEvent = server:createRemoteEvent("remoteEvent"),
            })

            local clientStaticStreams = {
                user0 = ClientStaticStream.new({
                    remoteEvent = server:getClient("user0"):getRemoteEvent("remoteEvent"),
                }),
                user1 = ClientStaticStream.new({
                    remoteEvent = server:getClient("user1"):getRemoteEvent("remoteEvent"),
                }),
                user2 = ClientStaticStream.new({
                    remoteEvent = server:getClient("user2"):getRemoteEvent("remoteEvent"),
                })
            }

            local staticStoreServer = serverStaticStream:create("store", {
                inventory = {},
            })

            staticStoreServer:dispatch("inventory", "insertValue", "gun")

            staticStoreServer:stream(server:getClient("user0"))
            staticStoreServer:stream(server:getClient("user1"))

            expect(clientStaticStreams.user0:get("store"):getValue("inventory")).to.be.a("table")
            expect(clientStaticStreams.user0:get("store"):getValue("inventory")[1]).to.equal("gun")

            expect(clientStaticStreams.user1:get("store"):getValue("inventory")).to.be.a("table")
            expect(clientStaticStreams.user1:get("store"):getValue("inventory")[1]).to.equal("gun")

            expect(clientStaticStreams.user2:get("store")).to.equal(nil)

            serverStaticStream:destroy()
            server:destroy()
        end)



        it("should fire the streamed signal on the client", function()

        end)
    end)

    describe("StaticStoreServer:unstream", function()
        it("should remove the static store with the passed owner on the client", function()

        end)

        it("should fire the unstreaming signal on the client", function()

        end)
    end)

    describe("StaticStoreServer:dispatch", function()
        it("should update the state on server", function()

        end)

        it("should fire")

        it("should properly update the client", function()

        end)
    end)

    describe("StaticStoreServer:getValue", function()
        it("should return a value that changes properly from server changes", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")

            local serverStaticStream = ServerStaticStream.new({
                remoteEvent = mockRemoteEvent,
            })

            serverStaticStream:create("store", {
                key0 = 0,
                key1 = {},
            }):stream("user")

            expect(serverStaticStream:get("store"):getValue("key0")).to.equal(0)
            expect(serverStaticStream:get("store"):getValue("key1")).to.be.a("table")
            expect(serverStaticStream:get("store"):getValue("key1")[1]).to.equal(nil)

            serverStaticStream:get("store"):dispatch("key0", "setValue", 1)
            serverStaticStream:get("store"):dispatch("key1", "insertValue", 1)

            expect(serverStaticStream:get("store"):getValue("key0")).to.equal(1)
            expect(serverStaticStream:get("store"):getValue("key1")[1]).to.equal(1)

            serverStaticStream:destroy()
            mockRemoteEvent:destroy()
        end)
    end)

    describe("StaticStoreServer:getChangedSignal", function()
        it("should return a changed signal that is fired properly from server changes", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")

            local serverStaticStream = ServerStaticStream.new({
                remoteEvent = mockRemoteEvent,
            })

            serverStaticStream:create("store", {
                key0 = 0,
                key1 = {},
            }):stream("user")

            local signal0 = serverStaticStream:getChangedSignal("key0")
            local signal1 = serverStaticStream:getChangedSignal("key1")

            expect(signal0).to.be.a("table")
            expect(getmetatable(signal0)).to.equal(Slick.Signal)

            expect(signal1).to.be.a("table")
            expect(getmetatable(signal1)).to.equal(Slick.Signal)

            expect(serverStaticStream:get("store"):getValue("key0")).to.equal(0)
            expect(serverStaticStream:get("store"):getValue("key1")).to.be.a("table")

            local promise0 = signal0:promise()
            local promise1 = signal1:promise()

            serverStaticStream:get("store"):dispatch("key0", "setValue", 1)
            serverStaticStream:get("store"):dispatch("key1", "insertValue", 1)

            expect(select(1, promise0:expect())).to.equal(1)
            expect(select(2, promise0:expect())).to.equal(0)

            expect(select(1, promise1:expect())[1]).to.equal(1)
            expect(select(2, promise1:expect())[1]).to.equal(nil)

            serverStaticStream:destroy()
            mockRemoteEvent:destroy()
        end)
    end)

    describe("StaticStoreServer:getReducedSignal", function()
        it("should return a reduced signal that is fired properly from server changes", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")

            local serverStaticStream = ServerStaticStream.new({
                remoteEvent = mockRemoteEvent,
            })

            serverStaticStream:create("store", {
                key0 = 0,
                key1 = {},
            }):stream("user")

            local signal0 = serverStaticStream:getReducedSignal("key0", "setValue")
            local signal1 = serverStaticStream:getReducedSignal("key1", "insertValue")

            expect(signal0).to.be.a("table")
            expect(getmetatable(signal0)).to.equal(Slick.Signal)

            expect(signal1).to.be.a("table")
            expect(getmetatable(signal1)).to.equal(Slick.Signal)

            expect(serverStaticStream:get("store"):getValue("key0")).to.equal(0)
            expect(serverStaticStream:get("store"):getValue("key1")).to.be.a("table")

            local promise0 = signal0:promise()
            local promise1 = signal1:promise()

            serverStaticStream:get("store"):dispatch("key0", "setValue", 1)
            serverStaticStream:get("store"):dispatch("key1", "insertValue", 1)

            expect(promise0:expect()).to.equal(1)
            expect(promise1:expect()).to.equal(1)

            serverStaticStream:destroy()
            mockRemoteEvent:destroy()
        end)
    end)
end