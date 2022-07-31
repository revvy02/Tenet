local MockNetwork = require(script.Parent.Parent.Parent.MockNetwork)
local TrueSignal = require(script.Parent.Parent.Parent.TrueSignal)
local Cleaner = require(script.Parent.Parent.Parent.Cleaner)

local ClientChannel = require(script.Parent.ClientChannel)
local ServerChannel = require(script.Parent.Parent.Server.ServerChannel)

return function()
    describe("StaticStoreClient:getValue", function()
        it("should return a value that changes properly from server changes", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

            local serverChannel = ServerChannel.new(mockRemoteEvent, mockRemoteFunction)
            local clientChannel = ClientChannel.new(mockRemoteEvent, mockRemoteFunction)

            local ssServer = serverChannel:create("store", {
                xp = 0,
                inv = {},
            })

            ssServer:subscribe("user")
            
            local ssClient = clientChannel:get("store")

            expect(ssClient:getValue("xp")).to.equal(0)
            expect(ssClient:getValue("inv")[1]).to.equal(nil)

            ssServer:dispatch("xp", "setValue", 1000)
            ssServer:dispatch("inv", "insertValue", "gun")

            expect(ssClient:getValue("xp")).to.equal(1000)
            expect(ssClient:getValue("inv")[1]).to.equal("gun")
        end)
    end)

    describe("StaticStoreClient:getChangedSignal", function()
        it("should return a changed signal that is fired properly from server changes", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

            local serverChannel = ServerChannel.new(mockRemoteEvent, mockRemoteFunction)
            local clientChannel = ClientChannel.new(mockRemoteEvent, mockRemoteFunction)

            local ssServer = serverChannel:create("store", {
                xp = 0,
                inv = {},
            })

            ssServer:subscribe("user")

            local ssClient = clientChannel:get("store")

            local xpSignal = ssClient:getChangedSignal("xp")
            local invSignal = ssClient:getChangedSignal("inv")

            expect(xpSignal).to.be.a("table")
            expect(getmetatable(xpSignal)).to.equal(TrueSignal)

            expect(invSignal).to.be.a("table")
            expect(getmetatable(invSignal)).to.equal(TrueSignal)

            expect(ssClient:getValue("xp")).to.equal(0)
            expect(ssClient:getValue("inv")[1]).to.equal(nil)

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

    describe("StaticStoreClient:getReducedSignal", function()
        it("should return a reduced signal that is fired properly from server changes", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

            local serverChannel = ServerChannel.new(mockRemoteEvent, mockRemoteFunction)
            local clientChannel = ClientChannel.new(mockRemoteEvent, mockRemoteFunction)

            local ssServer = serverChannel:create("store", {
                xp = 0,
                inv = {},
            })

            ssServer:subscribe("user")

            local ssClient = clientChannel:get("store")

            local xpSignal = ssClient:getReducedSignal("xp", "setValue")
            local invSignal = ssClient:getReducedSignal("inv", "insertValue")

            expect(xpSignal).to.be.a("table")
            expect(getmetatable(xpSignal)).to.equal(TrueSignal)

            expect(invSignal).to.be.a("table")
            expect(getmetatable(invSignal)).to.equal(TrueSignal)

            expect(ssClient:getValue("xp")).to.equal(0)
            expect(ssClient:getValue("inv")[1]).to.equal(nil)

            local xpPromise = xpSignal:promise()
            local invPromise = invSignal:promise()

            ssServer:dispatch("xp", "setValue", 1000)
            ssServer:dispatch("inv", "insertValue", "gun")

            expect(xpPromise:expect()).to.equal(1000)
            expect(invPromise:expect()).to.equal("gun")
        end)
    end)
end