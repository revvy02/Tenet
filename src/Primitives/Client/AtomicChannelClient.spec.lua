local MockNetwork = require(script.Parent.Parent.Parent.Parent.MockNetwork)
local TrueSignal = require(script.Parent.Parent.Parent.Parent.TrueSignal)

local ClientBroadcast = require(script.Parent.ClientBroadcast)
local ServerBroadcast = require(script.Parent.Parent.Server.ServerBroadcast)

return function()
    describe("AtomicChannelClient:getValue", function()
        it("should return a value that changes properly from server changes", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

            local serverBroadcast = ServerBroadcast.new(mockRemoteEvent, mockRemoteFunction)
            local clientBroadcast = ClientBroadcast.new(mockRemoteEvent, mockRemoteFunction)

            local acServer = serverBroadcast:createAtomicChannel("store", {
                xp = 0,
                inv = {},
            })

            acServer:subscribe("user")
            
            local acClient = clientBroadcast:getChannel("store")

            expect(acClient:getValue("xp")).to.equal(0)
            expect(acClient:getValue("inv")[1]).to.equal(nil)

            acServer:dispatch("setValue", "xp", 1000)
            acServer:dispatch("insertValue", "inv", "gun")

            expect(acClient:getValue("xp")).to.equal(1000)
            expect(acClient:getValue("inv")[1]).to.equal("gun")
        end)
    end)

    describe("AtomicChannelClient:getChangedSignal", function()
        it("should return a changed signal that is fired properly from server changes", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

            local serverBroadcast = ServerBroadcast.new(mockRemoteEvent, mockRemoteFunction)
            local clientBroadcast = ClientBroadcast.new(mockRemoteEvent, mockRemoteFunction)

            local ssServer = serverBroadcast:createAtomicChannel("store", {
                xp = 0,
                inv = {},
            })

            ssServer:subscribe("user")

            local ssClient = clientBroadcast:getChannel("store")

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

            ssServer:dispatch("setValue", "xp",  1000)
            ssServer:dispatch("insertValue", "inv", "gun")

            expect(select(1, xpPromise:expect())).to.equal(1000)
            expect(select(2, xpPromise:expect())).to.equal(0)

            expect(select(1, invPromise:expect())[1]).to.equal("gun")
            expect(select(2, invPromise:expect())[1]).to.equal(nil)
        end)
    end)

    describe("AtomicChannelClient:getReducedSignal", function()
        it("should return a reduced signal that is fired properly from server changes", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

            local serverBroadcast = ServerBroadcast.new(mockRemoteEvent, mockRemoteFunction)
            local clientBroadcast = ClientBroadcast.new(mockRemoteEvent, mockRemoteFunction)

            local ssServer = serverBroadcast:createAtomicChannel("store", {
                xp = 0,
                inv = {},
            })

            ssServer:subscribe("user")

            local ssClient = clientBroadcast:getChannel("store")

            local xpSignal = ssClient:getReducedSignal("setValue", "xp")
            local invSignal = ssClient:getReducedSignal("insertValue", "inv")

            expect(xpSignal).to.be.a("table")
            expect(getmetatable(xpSignal)).to.equal(TrueSignal)

            expect(invSignal).to.be.a("table")
            expect(getmetatable(invSignal)).to.equal(TrueSignal)

            expect(ssClient:getValue("xp")).to.equal(0)
            expect(ssClient:getValue("inv")[1]).to.equal(nil)

            local xpPromise = xpSignal:promise()
            local invPromise = invSignal:promise()

            ssServer:dispatch("setValue", "xp", 1000)
            ssServer:dispatch("insertValue", "inv", "gun")

            expect(xpPromise:expect()).to.equal(1000)
            expect(invPromise:expect()).to.equal("gun")
        end)
    end)
end