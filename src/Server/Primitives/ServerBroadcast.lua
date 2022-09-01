local Cleaner = require(script.Parent.Parent.Parent.Parent.Cleaner)
local TrueSignal = require(script.Parent.Parent.Parent.Parent.TrueSignal)

local Reducers = require(script.Parent.Parent.Parent.Shared.Reducers)
local Middleware = require(script.Parent.Parent.Parent.Server.Middleware)

local ServerSignal = require(script.Parent.ServerSignal)
local ServerCallback = require(script.Parent.ServerCallback)
local AtomicChannelServer = require(script.Parent.AtomicChannelServer)
local NonatomicChannelServer = require(script.Parent.NonatomicChannelServer)

--[=[
    Server Network class for selectively replicating states to client

    @class ServerBroadcast
]=]
local ServerBroadcast = {}
ServerBroadcast.__index = ServerBroadcast

--[=[
    Constructs a new ServerBroadcast object

    @param remoteEvent RemoteEvent
    @param remoteFunction RemoteFunction
    @param defaultReducersModule ModuleScript?
    @return ServerBroadcast
]=]
function ServerBroadcast.new(remoteEvent, remoteFunction, defaultReducersModule)
    local self = setmetatable({}, ServerBroadcast)

    self._defaultReducersModule = defaultReducersModule or Reducers.Mixed
    
    self._cleaner = Cleaner.new()
    self._channelCleaner = Cleaner.new()

    self._serverSignal = self._cleaner:give(ServerSignal.new(remoteEvent, {
        outboundMiddleware = {
            Middleware.Outbound.instanceKeyEncoder(),
        }
    }))
    
    self._serverCallback = self._cleaner:give(ServerCallback.new(remoteFunction))

    self._serverCallback:setCallback(function()
        return self._defaultReducersModule
    end)
    
    --[=[
        Signal that gets fired once a channel is created

        @prop created TrueSignal
        @readonly
        @within ServerBroadcast
    ]=]
    self.created = self._cleaner:give(TrueSignal.new())

    --[=[
        Signal that gets fired once a channel is removed

        @prop removed TrueSignal
        @readonly
        @within ServerBroadcast
    ]=]
    self.removed = self._cleaner:give(TrueSignal.new())
    
    return self
end

--[=[
    Creates an atomic channel on the server

    @param host any
    @param initialState table?
    @param reducersModule ModuleScript?
    @return AtomicChannelServer
]=]
function ServerBroadcast:createAtomicChannel(host, initialState, reducersModule)
    return AtomicChannelServer._new(self, host, initialState, reducersModule)
end

--[=[
    Creates an atomic channel on the server

    @param host any
    @param initialState table?
    @param reducersModule ModuleScript?
    @return NonatomicChannelServer
]=]
function ServerBroadcast:createNonatomicChannel(host, initialState, reducersModule)
    return NonatomicChannelServer._new(self, host, initialState, reducersModule)
end

--[=[
    Removes the channel from the server and any subscribed or streaming clients

    @param host any
]=]
function ServerBroadcast:removeChannel(host)
    self._channelCleaner:finalize(host)
end

--[=[
    Returns the channel with the passed host

    @param host any
    @param return AtomicChannelServer | NonatomicChannelServer
]=]
function ServerBroadcast:getChannel(host)
    return self._channelCleaner:get(host)
end

--[=[
    Removes any channels and prepares the ServerBroadcast object for garbage collection
]=]
function ServerBroadcast:destroy()
    self._channelCleaner:destroy()
    self._cleaner:destroy()
end

return ServerBroadcast