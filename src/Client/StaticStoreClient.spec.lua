local MockNetwork = require(script.Parent.Parent.Parent.MockNetwork)
local Slick = require(script.Parent.Parent.Parent.Slick)

local ClientStaticStream = require(script.Parent.ClientStaticStream)
local ServerStaticStream = require(script.Parent.Parent.Server.ServerStaticStream)

return function()
    describe("StaticStoreClient:getValue", function()
        it("should return a value that changes properly from server changes", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")

            local serverStaticStream = ServerStaticStream.new({
                remoteEvent = mockRemoteEvent,
            })

            local clientStaticStream = ClientStaticStream.new({
                remoteEvent = mockRemoteEvent,
            })

            serverStaticStream:create("store", {
                key0 = 0,
                key1 = {},
            }):stream("user")

            expect(clientStaticStream:get("store"):getValue("key0")).to.equal(0)
            expect(clientStaticStream:get("store"):getValue("key1")).to.be.a("table")
            expect(clientStaticStream:get("store"):getValue("key1")[1]).to.equal(nil)

            serverStaticStream:get("store"):dispatch("key0", "setValue", 1)
            serverStaticStream:get("store"):dispatch("key1", "insertValue", 1)

            expect(clientStaticStream:get("store"):getValue("key0")).to.equal(1)
            expect(clientStaticStream:get("store"):getValue("key1")[1]).to.equal(1)

            clientStaticStream:destroy()
            serverStaticStream:destroy()
            mockRemoteEvent:destroy()
        end)
    end)

    describe("StaticStoreClient:getChangedSignal", function()
        it("should return a changed signal that is fired properly from server changes", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")

            local serverStaticStream = ServerStaticStream.new({
                remoteEvent = mockRemoteEvent,
            })

            local clientStaticStream = ClientStaticStream.new({
                remoteEvent = mockRemoteEvent,
            })

            serverStaticStream:create("store", {
                key0 = 0,
                key1 = {},
            }):stream("user")

            local signal0 = clientStaticStream:getChangedSignal("key0")
            local signal1 = clientStaticStream:getChangedSignal("key1")

            expect(signal0).to.be.a("table")
            expect(getmetatable(signal0)).to.equal(Slick.Signal)

            expect(signal1).to.be.a("table")
            expect(getmetatable(signal1)).to.equal(Slick.Signal)

            expect(clientStaticStream:get("store"):getValue("key0")).to.equal(0)
            expect(clientStaticStream:get("store"):getValue("key1")).to.be.a("table")

            local promise0 = signal0:promise()
            local promise1 = signal1:promise()

            serverStaticStream:get("store"):dispatch("key0", "setValue", 1)
            serverStaticStream:get("store"):dispatch("key1", "insertValue", 1)

            expect(select(1, promise0:expect())).to.equal(1)
            expect(select(2, promise0:expect())).to.equal(0)

            expect(select(1, promise1:expect())[1]).to.equal(1)
            expect(select(2, promise1:expect())[1]).to.equal(nil)

            clientStaticStream:destroy()
            serverStaticStream:destroy()
            mockRemoteEvent:destroy()
        end)
    end)

    describe("StaticStoreClient:getReducedSignal", function()
        it("should return a reduced signal that is fired properly from server changes", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")

            local serverStaticStream = ServerStaticStream.new({
                remoteEvent = mockRemoteEvent,
            })

            local clientStaticStream = ClientStaticStream.new({
                remoteEvent = mockRemoteEvent,
            })

            serverStaticStream:create("store", {
                key0 = 0,
                key1 = {},
            }):stream("user")

            local signal0 = clientStaticStream:getReducedSignal("key0", "setValue")
            local signal1 = clientStaticStream:getReducedSignal("key1", "insertValue")

            expect(signal0).to.be.a("table")
            expect(getmetatable(signal0)).to.equal(Slick.Signal)

            expect(signal1).to.be.a("table")
            expect(getmetatable(signal1)).to.equal(Slick.Signal)

            expect(clientStaticStream:get("store"):getValue("key0")).to.equal(0)
            expect(clientStaticStream:get("store"):getValue("key1")).to.be.a("table")

            local promise0 = signal0:promise()
            local promise1 = signal1:promise()

            serverStaticStream:get("store"):dispatch("key0", "setValue", 1)
            serverStaticStream:get("store"):dispatch("key1", "insertValue", 1)

            expect(promise0:expect()).to.equal(1)
            expect(promise1:expect()).to.equal(1)

            clientStaticStream:destroy()
            serverStaticStream:destroy()
            mockRemoteEvent:destroy()
        end)
    end)
end