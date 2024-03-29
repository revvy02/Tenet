local Cleaner = require(script.Parent.Parent.Parent.Parent.Cleaner)
local Promise = require(script.Parent.Parent.Parent.Parent.Promise)
local TrueSignal = require(script.Parent.Parent.Parent.Parent.TrueSignal)

local Middleware = require(script.Parent.Parent.Parent.Middleware)

local ClientSignal = require(script.Parent.ClientSignal)
local ClientCallback = require(script.Parent.ClientCallback)
local AtomicChannelClient = require(script.Parent.AtomicChannelClient)
local NonatomicChannelClient = require(script.Parent.NonatomicChannelClient)

local handlers = {
    dispatch = function(self, _, host, reducer, key, ...)
        print(debug.traceback())
        print(reducer, key, ...)
        self:getChannel(host):_dispatch(reducer, key, ...)
    end,

    stream = function(self, _, host, key, value)
        self:getChannel(host):_stream(key, value)
    end,

    unstream = function(self, _, host, key)
        self:getChannel(host):_unstream(key)
    end,

    nonatomic = function(self, defaultReducers, host, initial, customReducers)
        self.subscribed:fire(host, self._cleaner:set(host, NonatomicChannelClient._new(self, host, initial, customReducers and require(customReducers) or defaultReducers and require(defaultReducers)), NonatomicChannelClient._destroy))
    end,

    atomic = function(self, defaultReducers, host, initial, customReducers)
        self.subscribed:fire(host, self._cleaner:set(host, AtomicChannelClient._new(self, host, initial, customReducers and require(customReducers) or defaultReducers and require(defaultReducers)), AtomicChannelClient._destroy))
    end,

    unsubscribe = function(self, _, host)
        self.unsubscribed:fire(host, self._cleaner:get(host))
        self._cleaner:finalize(host)
    end,
}

--[=[
    Server Network class for selectively receiving state

    @class ClientBroadcast
]=]
local ClientBroadcast = {}
ClientBroadcast.__index = ClientBroadcast

--[=[
    Removes any channels and prepares the ClientBroadcast object for garbage collection

    @private
]=]
function ClientBroadcast:_destroy()
    self._promise:cancel()
    self._cleaner:destroy()
end

--[=[
    Constructs a new ClientBroadcast object

    @param remoteEvent RemoteEvent
    @param remoteFunction RemoteFunction
    @return ClientBroadcast
]=]
function ClientBroadcast.new(remoteEvent, remoteFunction)
    local self = setmetatable({}, ClientBroadcast)

    self._hosts = table.freeze({})

    self._cleaner = Cleaner.new()

    self._clientSignal = self._cleaner:give(ClientSignal.new(remoteEvent, {
        inbound = {
            Middleware.Inbound.Client.clientInstanceKeyDecoder(),
        }
    }), ClientSignal._destroy)

    self._clientCallback = self._cleaner:give(ClientCallback.new(remoteFunction), ClientCallback._destroy)
    
    self._promise = self._clientCallback:callServerAsync()

    --[=[
        Signal that gets fired once a store is streamed in

        @prop subscribed TrueSignal
        @readonly
        @within ClientBroadcast
    ]=]
    self.subscribed = self._cleaner:give(TrueSignal.new())

    --[=[
        Signal that gets fired once a store begins unstreaming

        @prop unsubscribed TrueSignal
        @readonly
        @within ClientBroadcast
    ]=]
    self.unsubscribed = self._cleaner:give(TrueSignal.new())

    self._promise:andThen(function(defaultReducers)
        self._cleaner:give(self._clientSignal:connect(function(action, host, ...)
            handlers[action](self, defaultReducers, host, ...)
        end))
    end)

    return self
end

--[=[
    Returns the channel with the passed host

    @param host any
    @return AtomicChannelClient | NonatomicChannelClient
]=]
function ClientBroadcast:getChannel(host)
    return self._cleaner:get(host)
end

--[=[
    Returns a list of channel hosts that are subscribed

    @return {...any}
]=]
function ClientBroadcast:getHosts()
    return self._hosts
end

return ClientBroadcast