local MockNetwork = require(script.Parent.Parent.Parent.Parent.MockNetwork)
local Promise = require(script.Parent.Parent.Parent.Parent.Promise)

local Reducers = require(script.Parent.Parent.Parent.Reducers)

local ClientBroadcast = require(script.Parent.Parent.Client.ClientBroadcast)
local ServerBroadcast = require(script.Parent.ServerBroadcast)

return function()
    local function mapClientBroadcasts(id, client)
        return id, ClientBroadcast.new(client:getRemoteEvent("remoteEvent"), client:getRemoteFunction("remoteFunction"))
    end

    describe("ServerBroadcast.new", function()
        it("should create a new ServerBroadcast instance", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

            local serverBroadcast = ServerBroadcast.new(mockRemoteEvent, mockRemoteFunction)

            expect(serverBroadcast).to.be.a("table")
            expect(getmetatable(serverBroadcast)).to.equal(ServerBroadcast)
        end)
        
        it("should handle logging correctly", function()
            local logs = {}

            local server = MockNetwork.Server.new({"user1", "user2"})
            local clients = server:mapClients()

            local serverBroadcast = ServerBroadcast.new(server:createRemoteEvent("remoteEvent"), server:createRemoteFunction("remoteFunction"), {
                log = function(message, info)
                    table.insert(logs, {message = message, info = info})
                end,
            })

            local clientBroadcasts = server:mapClients(mapClientBroadcasts)

            clientBroadcasts.user1._clientSignal:fireServer("hax")

            expect(logs[1].message).to.equal("serverNetworkBlocker violation")
            expect(logs[1].info.client).to.equal(clients.user1)
            expect(logs[1].info.args[1]).to.equal("hax")
            expect(logs[1].info.tag).to.equal("serverBroadcast")

            local promise = clientBroadcasts.user2._clientCallback:callServerAsync("free coins")

            expect(logs[2].message).to.equal("serverRuntimeTypechecker violation")
            expect(logs[2].info.client).to.equal(clients.user2)
            expect(logs[2].info.args[1]).to.equal("free coins")
            expect(logs[1].info.tag).to.equal("serverBroadcast")
            
            expect(promise:getStatus()).to.equal(Promise.Status.Rejected)
        end)
    end)

    describe("ServerBroadcast:createAtomicChannel", function()
        it("should throw if a channel already exists with the passed host", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

            local serverBroadcast = ServerBroadcast.new(mockRemoteEvent, mockRemoteFunction)

            serverBroadcast:createAtomicChannel("store")

            expect(function()
                serverBroadcast:createAtomicChannel("store")
            end).to.throw()
        end)

        it("should return an atomic channel with the host", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

            local serverBroadcast = ServerBroadcast.new(mockRemoteEvent, mockRemoteFunction)

            local acServer = serverBroadcast:createAtomicChannel("store")

            expect(acServer).to.be.ok()
            expect(acServer).to.equal(serverBroadcast:getChannel("store"))
        end)

        it("should fire the created signal on server", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

            local serverBroadcast = ServerBroadcast.new(mockRemoteEvent, mockRemoteFunction)

            local promise = serverBroadcast.created:promise()

            expect(promise:getStatus()).to.equal(Promise.Status.Started)

            local acServer = serverBroadcast:createNonatomicChannel("store")

            expect(promise:getStatus()).to.equal(Promise.Status.Resolved)

            expect(select(1, promise:expect())).to.equal("store")
            expect(select(2, promise:expect())).to.equal(acServer)
        end)

        it("should work properly if initial state is passed", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

            local serverBroadcast = ServerBroadcast.new(mockRemoteEvent, mockRemoteFunction)

            local acServer = serverBroadcast:createAtomicChannel("main", {value1 = 2, value2 = 3})

            expect(acServer:getValue("value1")).to.equal(2)
            expect(acServer:getValue("value2")).to.equal(3)
        end)

        it("should use reducers passed in :createAtomicChannel always if they are included", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

            local serverBroadcast = ServerBroadcast.new(mockRemoteEvent, mockRemoteFunction, {
                module = Reducers.Dictionary,
            })

            local acServer = serverBroadcast:createAtomicChannel("main", {value1 = {}, value2 = 3}, Reducers.Value)

            expect(acServer:getValue("value1")).to.be.a("table")
            expect(acServer:getValue("value2")).to.equal(3)

            expect(function()
                acServer:dispatch("setIndex", "value1", "key1", 2)
            end).to.throw()

            expect(function()
                acServer:dispatch("setValue", "value1", 3)
                acServer:dispatch("setValue", "value2", 4)
            end).to.never.throw()

            expect(acServer:getValue("value1")).to.equal(3)
            expect(acServer:getValue("value2")).to.equal(4)
        end)

        it("should use mixed reducers by default if no reducers are passed in .new or :createAtomicChannel", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

            local serverBroadcast = ServerBroadcast.new(mockRemoteEvent, mockRemoteFunction)

            local acServer = serverBroadcast:createAtomicChannel("main", {value1 = {}, value2 = {}, value3 = 3})

            expect(#acServer:getValue("value1")).to.equal(0)
            expect(#acServer:getValue("value2")).to.equal(0)
            expect(acServer:getValue("value3")).to.equal(3)

            expect(function()
                acServer:dispatch("setIndex", "value1", "key1", 2)
                acServer:dispatch("insertValue", "value2", 1)
                acServer:dispatch("setValue", "value3", 4)
            end).to.never.throw()

            expect(acServer:getValue("value1").key1).to.equal(2)
            expect(acServer:getValue("value2")[1]).to.equal(1)
            expect(acServer:getValue("value3")).to.equal(4)
        end)

        it("should use the reducers passed in .new if no reducers are passed in :createAtomicChannel", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

            local serverBroadcast = ServerBroadcast.new(mockRemoteEvent, mockRemoteFunction, {
                module = Reducers.Dictionary
            })

            local acServer = serverBroadcast:createAtomicChannel("main", {value1 = {}, value2 = 3})

            expect(acServer:getValue("value1")).to.be.a("table")
            expect(acServer:getValue("value2")).to.equal(3)

            expect(function()
                acServer:dispatch("insertValue", "value1", 2)
            end).to.throw()

            expect(function()
                acServer:dispatch("setIndex", "value1", "key1", 1)
            end).to.never.throw()

            expect(acServer:getValue("value1").key1).to.equal(1)
        end)
    end)

    describe("ServerBroadcast:createNonatomicChannel", function()
        it("should throw if a channel already exists with the passed host", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

            local serverBroadcast = ServerBroadcast.new(mockRemoteEvent, mockRemoteFunction)

            serverBroadcast:createNonatomicChannel("store")

            expect(function()
                serverBroadcast:createNonatomicChannel("store")
            end).to.throw()
        end)

        it("should return an atomic channel with the host", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

            local serverBroadcast = ServerBroadcast.new(mockRemoteEvent, mockRemoteFunction)

            local ncServer = serverBroadcast:createNonatomicChannel("store")

            expect(ncServer).to.be.ok()
            expect(ncServer).to.equal(serverBroadcast:getChannel("store"))
        end)

        it("should fire the created signal on server", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

            local serverBroadcast = ServerBroadcast.new(mockRemoteEvent, mockRemoteFunction)

            local promise = serverBroadcast.created:promise()

            expect(promise:getStatus()).to.equal(Promise.Status.Started)

            local ncServer = serverBroadcast:createNonatomicChannel("store")

            expect(promise:getStatus()).to.equal(Promise.Status.Resolved)

            expect(select(1, promise:expect())).to.equal("store")
            expect(select(2, promise:expect())).to.equal(ncServer)
        end)

        it("should work properly if initial state is passed", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

            local serverBroadcast = ServerBroadcast.new(mockRemoteEvent, mockRemoteFunction)

            local ncServer = serverBroadcast:createNonatomicChannel("main", {value1 = 2, value2 = 3})

            expect(ncServer:getValue("value1")).to.equal(2)
            expect(ncServer:getValue("value2")).to.equal(3)
        end)

        it("should use reducers passed in :createAtomicChannel always if they are included", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

            local serverBroadcast = ServerBroadcast.new(mockRemoteEvent, mockRemoteFunction, {
                module = Reducers.Dictionary
            })

            local ncServer = serverBroadcast:createNonatomicChannel("main", {value1 = {}, value2 = 3}, Reducers.Value)

            expect(ncServer:getValue("value1")).to.be.a("table")
            expect(ncServer:getValue("value2")).to.equal(3)

            expect(function()
                ncServer:dispatch("setIndex", "value1", "key1", 2)
            end).to.throw()

            expect(function()
                ncServer:dispatch("setValue", "value1", 3)
                ncServer:dispatch("setValue", "value2", 4)
            end).to.never.throw()

            expect(ncServer:getValue("value1")).to.equal(3)
            expect(ncServer:getValue("value2")).to.equal(4)
        end)

        it("should use mixed reducers by default if no reducers are passed in .new or :createAtomicChannel", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

            local serverBroadcast = ServerBroadcast.new(mockRemoteEvent, mockRemoteFunction)

            local ncServer = serverBroadcast:createNonatomicChannel("main", {value1 = {}, value2 = {}, value3 = 3})

            expect(#ncServer:getValue("value1")).to.equal(0)
            expect(#ncServer:getValue("value2")).to.equal(0)
            expect(ncServer:getValue("value3")).to.equal(3)

            expect(function()
                ncServer:dispatch("setIndex", "value1", "key1", 2)
                ncServer:dispatch("insertValue", "value2", 1)
                ncServer:dispatch("setValue", "value3", 4)
            end).to.never.throw()

            expect(ncServer:getValue("value1").key1).to.equal(2)
            expect(ncServer:getValue("value2")[1]).to.equal(1)
            expect(ncServer:getValue("value3")).to.equal(4)
        end)

        it("should use the reducers passed in .new if no reducers are passed in :createAtomicChannel", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

            local serverBroadcast = ServerBroadcast.new(mockRemoteEvent, mockRemoteFunction, {
                module = Reducers.Dictionary
            })

            local ncServer = serverBroadcast:createNonatomicChannel("main", {value1 = {}, value2 = 3})

            expect(ncServer:getValue("value1")).to.be.a("table")
            expect(ncServer:getValue("value2")).to.equal(3)

            expect(function()
                ncServer:dispatch("insertValue", "value1", 2)
            end).to.throw()

            expect(function()
                ncServer:dispatch("setIndex", "value1", "key1", 1)
            end).to.never.throw()

            expect(ncServer:getValue("value1").key1).to.equal(1)
        end)
    end)

    describe("ServerBroadcast:removeChannel", function()
        it("should fire the removed signal", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

            local serverBroadcast = ServerBroadcast.new(mockRemoteEvent, mockRemoteFunction)

            local promise = serverBroadcast.removed:promise()

            expect(promise:getStatus()).to.equal(Promise.Status.Started)

            serverBroadcast:createAtomicChannel("store")
            serverBroadcast:createNonatomicChannel("bodega")

            serverBroadcast:removeChannel("bodega")

            expect(promise:getStatus()).to.equal(Promise.Status.Resolved)

            expect(promise:expect()).to.equal("bodega")
        end)

        it("should fire the unsubscribed signal on subscribed clients", function()
            local server = MockNetwork.Server.new({"user1", "user2"})
            local clients = server:mapClients()

            local serverBroadcast = ServerBroadcast.new(server:createRemoteEvent("remoteEvent"), server:createRemoteFunction("remoteFunction"))
            local clientBroadcasts = server:mapClients(mapClientBroadcasts)

            local acServer = serverBroadcast:createAtomicChannel("store")

            acServer:subscribe(clients.user1)
            acServer:subscribe(clients.user2)

            local user1promise = clientBroadcasts.user1.unsubscribed:promise()
            local user2promise = clientBroadcasts.user2.unsubscribed:promise()

            expect(user1promise:getStatus()).to.equal(Promise.Status.Started)
            expect(user2promise:getStatus()).to.equal(Promise.Status.Started)

            serverBroadcast:removeChannel("store")

            expect(user1promise:getStatus()).to.equal(Promise.Status.Resolved)
            expect(user2promise:getStatus()).to.equal(Promise.Status.Resolved)

            expect(user1promise:expect()).to.equal("store")
            expect(user2promise:expect()).to.equal("store")
        end)

        it("should make this channel inaccessible from getChannel", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

            local serverBroadcast = ServerBroadcast.new(mockRemoteEvent, mockRemoteFunction)

            serverBroadcast:createAtomicChannel("store")
            expect(serverBroadcast:getChannel("store")).to.be.ok()

            serverBroadcast:removeChannel("store")
            expect(serverBroadcast:getChannel("store")).to.never.be.ok()
        end)
    end)

    describe("ServerBroadcast:getChannel", function()
        it("should return nil if no channel exists for the host", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

            local serverBroadcast = ServerBroadcast.new(mockRemoteEvent, mockRemoteFunction)

            expect(serverBroadcast:getChannel("store")).to.never.be.ok()
        end)

        it("should return the store for the owner if it exists", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

            local serverBroadcast = ServerBroadcast.new(mockRemoteEvent, mockRemoteFunction)

            local acServer = serverBroadcast:createAtomicChannel("store")
            
            expect(acServer).to.be.ok()
            expect(serverBroadcast:getChannel("store")).to.equal(acServer)
        end)
    end)

    describe("ServerBroadcast:getHosts", function()
        it("should return a list of all existing hosts", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

            local serverBroadcast = ServerBroadcast.new(mockRemoteEvent, mockRemoteFunction)

            serverBroadcast:createAtomicChannel("host1")
            serverBroadcast:createNonatomicChannel("host2")
            serverBroadcast:createAtomicChannel(1)

            local hosts = serverBroadcast:getHosts()

            expect(table.find(hosts, "host1")).to.be.ok()
            expect(table.find(hosts, "host2")).to.be.ok()
            expect(table.find(hosts, "host3")).to.never.be.ok()
            expect(table.find(hosts, 1)).to.be.ok()

            expect(#hosts).to.equal(3)
        end)

        it("should return a list that's frozen", function()
            local mockRemoteEvent = MockNetwork.MockRemoteEvent.new("user")
            local mockRemoteFunction = MockNetwork.MockRemoteFunction.new("user")

            local serverBroadcast = ServerBroadcast.new(mockRemoteEvent, mockRemoteFunction)

            local hosts = serverBroadcast:getHosts()

            expect(table.isfrozen(hosts)).to.equal(true)
        end)
    end)
end