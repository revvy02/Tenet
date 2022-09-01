local Slick = require(script.Parent.Parent.Parent.Parent.Slick)
local Cleaner = require(script.Parent.Parent.Parent.Parent.Cleaner)
local TrueSignal = require(script.Parent.Parent.Parent.Parent.TrueSignal)

local NonatomicChannelServer = {}
NonatomicChannelServer.__index = NonatomicChannelServer

function NonatomicChannelServer._new(serverBroadcast, host, initialState, reducersModule)
    assert(serverBroadcast._channelCleaner:get(host) == nil, string.format("Cannot create more than one channel for host (%s)", tostring(host)))

    local self = setmetatable({}, NonatomicChannelServer)
    
    self._serverBroadcast = serverBroadcast

    self._host = host
    self._reducersModule = reducersModule or self._serverBroadcast._defaultReducersModule
    
    self._streamers = {}
    self._subscribers = {}

    self._cleaner = Cleaner.new()

    self._store = self._cleaner:give(Slick.Store.new(initialState and table.clone(initialState), require(self._reducersModule)))

    self.reduced = self._store.reduced
    self.changed = self._store.changed
    
    self.subscribed = self._cleaner:give(TrueSignal.new())
    self.unsubscribed = self._cleaner:give(TrueSignal.new())
    self.streamed = self._cleaner:give(TrueSignal.new())
    self.unstreamed = self._cleaner:give(TrueSignal.new())

    self._cleaner:give(self._store.reduced:connect(function(key, reducer, ...)
        self._serverBroadcast._serverSignal:fireClients(self:getStreamedSubscribers(), "dispatch", self._host, key, reducer, ...)
    end))

    self._serverBroadcast._channelCleaner:set(host, self, NonatomicChannelServer._destroy)
    self._serverBroadcast.created:fire(host, self)

    return self
end




function NonatomicChannelServer:getSubscribers()
    return table.clone(self._subscribers)
end

function NonatomicChannelServer:getStreamers(key)
    return self._streamers[key] and table.clone(self._streamers[key]) or {}
end

function NonatomicChannelServer:getStreamedSubscribers(key)
    local list = {}

    for _, player in self._subscribers do
        if self:isStreamed(key, player) then
            table.insert(list, player)
        end
    end

    return list
end

function NonatomicChannelServer:isSubscribed(player)
    return table.find(self._subscribers, player) ~= nil
end

function NonatomicChannelServer:isStreamed(key, player)
    return self._streamers[key] and table.find(self._streamers[key], player) ~= nil
end

function NonatomicChannelServer:getSnapshot(player)
    local state = {}

    for key in self._streamers do
        if self:isStreamed(key, player) then
            state[key] = self:getValue(key)
        end
    end

    return state
end




function NonatomicChannelServer:subscribe(player)
    if self:isSubscribed(player) then
        return
    end

    table.insert(self._subscribers, player)

    self._serverBroadcast._serverSignal:fireClient(player, "nonatomic", self._host, self:getSnapshot(player), self._reducersModule)
    self.subscribed:fire(player)
end

function NonatomicChannelServer:unsubscribe(player)
    if not self:isSubscribed(player) then
        return
    end

    table.remove(self._subscribers, table.find(self._subscribers, player))

    self._serverBroadcast._serverSignal:fireClient(player, "unsubscribe", self._host)
    self.unsubscribed:fire(player)
end



function NonatomicChannelServer:stream(key, player)
    if self:isStreamed(key, player) then
        return
    end

    local list = self._streamers[key]

    if not list then
        list = {}
        self._streamers[key] = list
    end

    table.insert(list, player)

    self.streamed:fire(key, player)

    if not self:isSubscribed(player) then
        return
    end

    self._serverBroadcast._serverSignal:fireClient(player, "stream", self._host, key, self:getValue(key))
end

function NonatomicChannelServer:unstream(key, player)
    if not self:isStreamed(key, player) then
        return
    end

    local list = self._streamers[key]
    table.remove(list, table.find(list, player))

    self.unstreamed:fire(key, player)

    if self:isSubscribed(player) then
        return
    end

    self._serverBroadcast._serverSignal:fireClient(player, "unstream", self._host, key)
end






function NonatomicChannelServer:dispatch(key, reducer, ...)
    self._store:dispatch(key, reducer, ...)
end

function NonatomicChannelServer:getValue(key)
    return self._store:getValue(key)
end

function NonatomicChannelServer:getChangedSignal(key)
    return self._store:getChangedSignal(key)
end

function NonatomicChannelServer:getReducedSignal(key, reducer)
    return self._store:getReducedSignal(key, reducer)
end



function NonatomicChannelServer:_destroy()
    for _, player in self:getSubscribers() do
        self:unsubscribe(player)
    end

    table.clear(self._streamers)

    self._serverBroadcast.removed:fire(self._host)

    self._cleaner:destroy()
end

return NonatomicChannelServer