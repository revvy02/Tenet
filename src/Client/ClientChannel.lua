local Cleaner = require(script.Parent.Parent.Parent.Cleaner)
local Promise = require(script.Parent.Parent.Parent.Promise)
local TrueSignal = require(script.Parent.Parent.Parent.TrueSignal)

local ClientSignal = require(script.Parent.ClientSignal)
local ClientCallback = require(script.Parent.ClientCallback)
local StaticStoreClient = require(script.Parent.StaticStoreClient)
local DynamicStoreClient = require(script.Parent.DynamicStoreClient)

local handlers = {
    dispatch = function(self, _, owner, key, reducer, ...)
        self:get(owner):_dispatch(key, reducer, ...)
    end,



    stream = function(self, _, owner, key, value)
        self:get(owner):_stream(key, value)
    end,

    unstream = function(self, _, owner, key)
        self:get(owner):_unstream(key)
    end,



    dynamic = function(self, module, owner, initial)
        self.subscribed:fire(owner, self._cleaner:set(owner, DynamicStoreClient._new(initial, module and require(module)), DynamicStoreClient._destroy))
    end,

    static = function(self, module, owner, initial)
        self.subscribed:fire(owner, self._cleaner:set(owner, StaticStoreClient._new(initial, module and require(module)), StaticStoreClient._destroy))
    end,

    unsubscribe = function(self, _, owner)
        self.unsubscribed:fire(owner, self._cleaner:get(owner))
        self._cleaner:finalize(owner)
    end,
}

local ClientChannel = {}
ClientChannel.__index = ClientChannel

function ClientChannel.new(remoteEvent, remoteFunction)
    local self = setmetatable({}, ClientChannel)

    self._cleaner = Cleaner.new()
    self._clientSignal = self._cleaner:give(ClientSignal.new(remoteEvent))
    self._clientCallback = self._cleaner:give(ClientCallback.new(remoteFunction))
    
    self._promise = self._clientCallback:callServerAsync()

    --[=[
        Signal that gets fired once a store is streamed in

        @prop streamed TrueSignal
        @readonly
        @within ClientChannel
    ]=]
    self.subscribed = self._cleaner:give(TrueSignal.new())

    --[=[
        Signal that gets fired once a store begins unstreaming

        @prop unstreaming TrueSignal
        @readonly
        @within ClientChannel
    ]=]
    self.unsubscribed = self._cleaner:give(TrueSignal.new())

    self._promise:andThen(function(module)
        self._cleaner:give(self._clientSignal:connect(function(action, owner, ...)
            handlers[action](self, module, owner, ...)
        end))
    end)

    return self
end

function ClientChannel:get(owner)
    return self._cleaner:get(owner)
end

function ClientChannel:destroy()
    self._promise:cancel()
    self._cleaner:destroy()
    self.destroyed = true
end

return ClientChannel