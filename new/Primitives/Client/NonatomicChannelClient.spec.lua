local MockNetwork = require(script.Parent.Parent.Parent.Parent.MockNetwork)
local TrueSignal = require(script.Parent.Parent.Parent.Parent.TrueSignal)

local ClientBroadcast = require(script.Parent.ClientBroadcast)
local ServerBroadcast = require(script.Parent.Parent.Parent.Server.Primitives.ServerBroadcast)

return function()
    describe("NonatomicChannelClient:getValue", function()
        it("should return a value that changes properly from server changes", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

            local serverBroadcast = ServerBroadcast.new(mockRemoteEvent, mockRemoteFunction)
            local clientBroadcast = ClientBroadcast.new(mockRemoteEvent, mockRemoteFunction)

            local ncServer = serverBroadcast:createNonatomicChannel("store", {
                xp = 0,
                inv = {},
            })

            ncServer:subscribe("user")
            
            ncServer:stream("xp", "user")
            ncServer:stream("inv", "user")

            local ncClient = clientBroadcast:getChannel("store")

            expect(ncClient:getValue("xp")).to.equal(0)
            expect(ncClient:getValue("inv")[1]).to.equal(nil)

            ncServer:dispatch("xp", "setValue", 1000)
            ncServer:dispatch("inv", "insertValue", "gun")

            expect(ncClient:getValue("xp")).to.equal(1000)
            expect(ncClient:getValue("inv")[1]).to.equal("gun")
        end)
    end)

    describe("NonatomicChannelClient:getChangedSignal", function()
        it("should return a changed signal that is fired properly from server changes", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

            local serverBroadcast = ServerBroadcast.new(mockRemoteEvent, mockRemoteFunction)
            local clientBroadcast = ClientBroadcast.new(mockRemoteEvent, mockRemoteFunction)

            local ncServer = serverBroadcast:createNonatomicChannel("store", {
                xp = 0,
                inv = {},
            })

            ncServer:subscribe("user")

            ncServer:stream("xp", "user")
            ncServer:stream("inv", "user")

            local ncClient = clientBroadcast:getChannel("store")

            local xpSignal = ncClient:getChangedSignal("xp")
            local invSignal = ncClient:getChangedSignal("inv")

            expect(xpSignal).to.be.a("table")
            expect(getmetatable(xpSignal)).to.equal(TrueSignal)

            expect(invSignal).to.be.a("table")
            expect(getmetatable(invSignal)).to.equal(TrueSignal)

            expect(ncClient:getValue("xp")).to.equal(0)
            expect(ncClient:getValue("inv")[1]).to.equal(nil)

            local xpPromise = xpSignal:promise()
            local invPromise = invSignal:promise()

            ncServer:dispatch("xp", "setValue", 1000)
            ncServer:dispatch("inv", "insertValue", "gun")

            expect(select(1, xpPromise:expect())).to.equal(1000)
            expect(select(2, xpPromise:expect())).to.equal(0)

            expect(select(1, invPromise:expect())[1]).to.equal("gun")
            expect(select(2, invPromise:expect())[1]).to.equal(nil)
        end)
    end)

    describe("NonatomicChannelClient:getReducedSignal", function()
        it("should return a reduced signal that is fired properly from server changes", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

            local serverBroadcast = ServerBroadcast.new(mockRemoteEvent, mockRemoteFunction)
            local clientBroadcast = ClientBroadcast.new(mockRemoteEvent, mockRemoteFunction)

            local ncServer = serverBroadcast:createNonatomicChannel("store", {
                xp = 0,
                inv = {},
            })

            ncServer:subscribe("user")

            ncServer:stream("xp", "user")
            ncServer:stream("inv", "user")
            
            local ncClient = clientBroadcast:getChannel("store")

            local xpSignal = ncClient:getReducedSignal("xp", "setValue")
            local invSignal = ncClient:getReducedSignal("inv", "insertValue")

            expect(xpSignal).to.be.a("table")
            expect(getmetatable(xpSignal)).to.equal(TrueSignal)

            expect(invSignal).to.be.a("table")
            expect(getmetatable(invSignal)).to.equal(TrueSignal)

            expect(ncClient:getValue("xp")).to.equal(0)
            expect(ncClient:getValue("inv")[1]).to.equal(nil)

            local xpPromise = xpSignal:promise()
            local invPromise = invSignal:promise()

            ncServer:dispatch("xp", "setValue", 1000)
            ncServer:dispatch("inv", "insertValue", "gun")

            expect(xpPromise:expect()).to.equal(1000)
            expect(invPromise:expect()).to.equal("gun")
        end)
    end)
end