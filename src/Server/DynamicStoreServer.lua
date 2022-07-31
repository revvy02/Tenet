local Slick = require(script.Parent.Parent.Parent.Slick)
local Cleaner = require(script.Parent.Parent.Parent.Cleaner)
local TrueSignal = require(script.Parent.Parent.Parent.TrueSignal)

local DynamicStoreServer = {}
DynamicStoreServer.__index = DynamicStoreServer

function DynamicStoreServer._new(serverChannel, owner, initial)
    local self = setmetatable({}, DynamicStoreServer)

    self._owner = owner
    self._serverChannel = serverChannel

    self._viewers = {}
    self._subscribers = {}

    self._cleaner = Cleaner.new()
    self._store = self._cleaner:give(Slick.Store.new(initial, self._serverChannel._module and require(self._serverChannel._module)))

    self.reduced = self._store.reduced
    self.changed = self._store.changed
    
    self.subscribed = self._cleaner:give(TrueSignal.new())
    self.unsubscribed = self._cleaner:give(TrueSignal.new())
    self.streamed = self._cleaner:give(TrueSignal.new())
    self.unstreamed = self._cleaner:give(TrueSignal.new())

    self._cleaner:give(self._store.reduced:connect(function(key, reducer, ...)
        self._serverChannel._serverSignal:fireClients(self:getStreamingSubscribers(), "dispatch", self._owner, key, reducer, ...)
    end))

    self._serverChannel._cleaner:set(owner, self)
    self._serverChannel.created:fire(owner, self)

    return self
end




function DynamicStoreServer:getSubscribers()
    return table.clone(self._subscribers)
end

function DynamicStoreServer:getStreamingSubscribers(key)
    
end

function DynamicStoreServer:isSubscribed(player)
    return table.find(self._subscribers, player) ~= nil
end

function DynamicStoreServer:isStreaming(key, player)

end




function DynamicStoreServer:subscribe(player)
    if self:isSubscribed(player) then
        return
    end

    table.insert(self._subscribers, player)

    self._serverSignal:fireClient(player, "dynamic", self._owner)
end

function DynamicStoreServer:unsubscribe(player)
    if not self:isSubscribed(player) then
        return
    end

    table.remove(self._subscribers, table.find(self._subscribers, player))

    self._serverSignal:fireClient(player, "unsubscribe", self._owner)
end





function DynamicStoreServer:stream(key, player)
    if not self:isStreaming(key, player) then
        return
    end

    local list = self._viewers[key]

    if not list then
        list = {}
        self._viewers[key] = list
    end

    table.insert(list, player)

    if self:isSubscribed(player) then
        return
    end

    self._serverSignal:fireClient(player, "stream", self._owner, key, self:getValue(key))
end

function DynamicStoreServer:unstream(key, player)
    if not self:isStreaming(key, player) then
        return
    end

    local list = self._viewers[key]

    table.remove(list, table.find(list, player))

    if self:isSubscribed(player) then
        return
    end
    
    self._serverSignal:fireClient(player, "unstream", self._owner, key)
end






function DynamicStoreServer:dispatch(key, reducer, ...)
    self._store:dispatch(key, reducer, ...)
end

function DynamicStoreServer:getValue(key)
    return self._store:getValue(key)
end

function DynamicStoreServer:getChangedSignal(key)
    return self._store:getChangedSignal(key)
end

function DynamicStoreServer:getReducedSignal(key, reducer)
    return self._store:getReducedSignal(key, reducer)
end





function DynamicStoreServer:destroy()
    for _, player in self:getSubscribers() do
        self:unsubscribe(player)
    end

    self._serverChannel.removed:fire(self._owner)

    self._cleaner:destroy()
    self.destroyed = true
end

return DynamicStoreServer