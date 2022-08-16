local Cleaner = require(script.Parent.Parent.Parent.Cleaner)
local TrueSignal = require(script.Parent.Parent.Parent.TrueSignal)

local Reducers = require(script.Parent.Parent.Parent.Reducers)

local ServerSignal = require(script.Parent.ServerSignal)
local ServerCallback = require(script.Parent.ServerCallback)
local AtomicChannelServer = require(script.Parent.AtomicChannelServer)
local NonatomicChannelServer = require(script.Parent.NonatomicChannelServer)

local ServerBroadcast = {}
ServerBroadcast.__index = ServerBroadcast

function ServerBroadcast.new(remoteEvent, remoteFunction, defaultReducersModule)
    local self = setmetatable({}, ServerBroadcast)

    self._defaultReducersModule = defaultReducersModule or Reducers.Mixed
    
    self._cleaner = Cleaner.new()
    self._channelCleaner = Cleaner.new()

    self._serverSignal = self._cleaner:give(ServerSignal.new(remoteEvent))
    self._serverCallback = self._cleaner:give(ServerCallback.new(remoteFunction))

    self._serverCallback:setCallback(function()
        return self._defaultReducersModule
    end)

    self.created = self._cleaner:give(TrueSignal.new())
    self.removed = self._cleaner:give(TrueSignal.new())

    return self
end

function ServerBroadcast:createAtomicChannel(host, initialState, reducersModule)
    return AtomicChannelServer._new(self, host, initialState, reducersModule)
end

function ServerBroadcast:createNonatomicChannel(host, initialState, reducersModule)
    return NonatomicChannelServer._new(self, host, initialState, reducersModule)
end

function ServerBroadcast:removeChannel(host)
    self._channelCleaner:finalize(host)
end

function ServerBroadcast:getChannel(host)
    return self._channelCleaner:get(host)
end

function ServerBroadcast:destroy()
    self._channelCleaner:destroy()
    self._cleaner:destroy()
end

return ServerBroadcast