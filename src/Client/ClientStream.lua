local Cleaner = require(script.Parent.Parent.Parent.Cleaner)
local Promise = require(script.Parent.Parent.Parent.Promise)
local TrueSignal = require(script.Parent.Parent.Parent.TrueSignal)

local ClientSignal = require(script.Parent.ClientSignal)
local StaticStoreClient = require(script.Parent.StaticStoreClient)
local DynamicStoreClient = require(script.Parent.DynamicStoreClient)

local handlers = {
    dispatch = function(self, owner, key, reducer, ...)
        self:get(owner):_dispatch(key, reducer, ...)
    end,

    load = function(self, owner, key, value)
        self:get(owner):_load(key, value)
    end,

    unload = function(self, owner, key)
        self:get(owner):_unload(key)
    end,

    dynamic = function(self, owner, initial, module)
        self.streamed:fire(owner, self._cleaner:set(owner, DynamicStoreClient._new(initial, module and require(module)), DynamicStoreClient._destroy))
    end,

    static = function(self, owner, initial, module)
        self.streamed:fire(owner, self._cleaner:set(owner, StaticStoreClient._new(initial, module and require(module)), StaticStoreClient._destroy))
    end,

    unstream = function(self, owner)
        self.unstreaming:fire(owner, self._cleaner:get(owner))
        self._cleaner:finalize(owner)
    end,
}

local ClientStream = {}
ClientStream.__index = ClientStream

function ClientStream.new(remoteEvent)
    local self = setmetatable({}, ClientStream)

    self._cleaner = Cleaner.new()
    self._clientSignal = self._cleaner:give(ClientSignal.new(remoteEvent))

    --[=[
        Signal that gets fired once a store is streamed in

        @prop streamed TrueSignal
        @readonly
        @within ClientStream
    ]=]
    self.streamed = self._cleaner:give(TrueSignal.new())

    --[=[
        Signal that gets fired once a store begins unstreaming

        @prop unstreaming TrueSignal
        @readonly
        @within ClientStream
    ]=]
    self.unstreaming = self._cleaner:give(TrueSignal.new())

    self._cleaner:give(self._clientSignal:connect(function(action, owner, ...)
        handlers[action](self, owner, ...)
    end))

    return self
end

function ClientStream:get(owner)
    return self._cleaner:get(owner)
end

function ClientStream:streamedAsync(owner)
    if self:get(owner) then
        return Promise.resolve()
    end

    return Promise.fromEvent(self.streamed, function(streamedOwner)
        return streamedOwner == owner
    end)
end

function ClientStream:destroy()
    self._cleaner:destroy()
    self.destroyed = true
end

return ClientStream