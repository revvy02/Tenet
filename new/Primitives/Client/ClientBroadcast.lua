local Cleaner = require(script.Parent.Parent.Parent.Parent.Cleaner)
local Promise = require(script.Parent.Parent.Parent.Parent.Promise)
local TrueSignal = require(script.Parent.Parent.Parent.Parent.TrueSignal)

local Middleware = require(script.Parent.Parent.Parent.Client.Middleware)

local ClientSignal = require(script.Parent.ClientSignal)
local ClientCallback = require(script.Parent.ClientCallback)
local AtomicChannelClient = require(script.Parent.AtomicChannelClient)
local NonatomicChannelClient = require(script.Parent.NonatomicChannelClient)

local handlers = {
    dispatch = function(self, _, host, key, reducer, ...)
        self:getChannel(host):_dispatch(key, reducer, ...)
    end,

    stream = function(self, _, host, key, value)
        self:getChannel(host):_stream(key, value)
    end,

    unstream = function(self, _, host, key)
        self:getChannel(host):_unstream(key)
    end,

    nonatomic = function(self, defaultReducers, host, initial, customReducers)
        self.subscribed:fire(host, self._cleaner:set(host, NonatomicChannelClient._new(initial, customReducers and require(customReducers) or defaultReducers and require(defaultReducers)), NonatomicChannelClient._destroy))
    end,

    atomic = function(self, defaultReducers, host, initial, customReducers)
        self.subscribed:fire(host, self._cleaner:set(host, AtomicChannelClient._new(initial, customReducers and require(customReducers) or defaultReducers and require(defaultReducers)), AtomicChannelClient._destroy))
    end,

    unsubscribe = function(self, _, host)
        self.unsubscribed:fire(host, self._cleaner:get(host))
        self._cleaner:finalize(host)
    end,
}

local ClientBroadcast = {}
ClientBroadcast.__index = ClientBroadcast

function ClientBroadcast.new(remoteEvent, remoteFunction)
    local self = setmetatable({}, ClientBroadcast)

    self._cleaner = Cleaner.new()

    self._clientSignal = self._cleaner:give(ClientSignal.new(remoteEvent,{
        inboundMiddleware = {
            Middleware.Inbound.instanceKeyDecoder(),
        }
    }))

    self._clientCallback = self._cleaner:give(ClientCallback.new(remoteFunction))
    
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
            print(action)
            handlers[action](self, defaultReducers, host, ...)
        end))
    end)

    return self
end

function ClientBroadcast:getChannel(host)
    return self._cleaner:get(host)
end

function ClientBroadcast:destroy()
    self._promise:cancel()
    self._cleaner:destroy()
end

return ClientBroadcast