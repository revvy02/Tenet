local Slick = require(script.Parent.Parent.Parent.Slick)
local Cleaner = require(script.Parent.Parent.Parent.Cleaner)
local TrueSignal = require(script.Parent.Parent.Parent.TrueSignal)

local AtomicChannelServer = {}
AtomicChannelServer.__index = AtomicChannelServer

function AtomicChannelServer._new(serverBroadcast, host, initialState, reducersModule)
    assert(serverBroadcast._channelCleaner:get(host) == nil, string.format("Cannot create more than one channel for host (%s)", tostring(host)))

    local self = setmetatable({}, AtomicChannelServer)
    
    self._serverBroadcast = serverBroadcast

    self._host = host
    self._reducersModule = reducersModule or self._serverBroadcast._defaultReducersModule

    self._subscribers = {}

    self._cleaner = Cleaner.new()

    self._store = self._cleaner:give(Slick.Store.new(initialState and table.clone(initialState), require(self._reducersModule)))

    self.reduced = self._store.reduced
    self.changed = self._store.changed
    
    self.subscribed = self._cleaner:give(TrueSignal.new())
    self.unsubscribed = self._cleaner:give(TrueSignal.new())

    self._cleaner:give(self._store.reduced:connect(function(key, reducer, ...)
        self._serverBroadcast._serverSignal:fireClients(self:getSubscribers(), "dispatch", self._host, key, reducer, ...)
    end))

    self._serverBroadcast._channelCleaner:set(host, self, AtomicChannelServer._destroy)
    self._serverBroadcast.created:fire(host, self)

    return self
end

function AtomicChannelServer:getSubscribers()
    return table.clone(self._subscribers)
end

function AtomicChannelServer:isSubscribed(player)
    return table.find(self._subscribers, player) ~= nil
end



function AtomicChannelServer:subscribe(player)
    if self:isSubscribed(player) then
        return
    end

    table.insert(self._subscribers, player)

    self._serverBroadcast._serverSignal:fireClient(player, "atomic", self._host, self._store:getState(), self._reducersModule)
    self.subscribed:fire(player)
end

function AtomicChannelServer:unsubscribe(player)
    if not self:isSubscribed(player) then
        return
    end

    table.remove(self._subscribers, table.find(self._subscribers, player))

    self._serverBroadcast._serverSignal:fireClient(player, "unsubscribe", self._host)
    self.unsubscribed:fire(player)
end




function AtomicChannelServer:dispatch(key, reducer, ...)
    self._store:dispatch(key, reducer, ...)
end

function AtomicChannelServer:getValue(key)
    return self._store:getValue(key)
end

function AtomicChannelServer:getChangedSignal(key)
    return self._store:getChangedSignal(key)
end

function AtomicChannelServer:getReducedSignal(key, reducer)
    return self._store:getReducedSignal(key, reducer)
end




function AtomicChannelServer:_destroy()
    for _, player in self:getSubscribers() do
        self:unsubscribe(player)
    end

    self._serverBroadcast.removed:fire(self._host)

    self._cleaner:destroy()
    self.destroyed = true
end

return AtomicChannelServer