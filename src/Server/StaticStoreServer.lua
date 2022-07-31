local Slick = require(script.Parent.Parent.Parent.Slick)
local Cleaner = require(script.Parent.Parent.Parent.Cleaner)
local TrueSignal = require(script.Parent.Parent.Parent.TrueSignal)

local StaticStoreServer = {}
StaticStoreServer.__index = StaticStoreServer

function StaticStoreServer._new(serverChannel, owner, initial)
    local self = setmetatable({}, StaticStoreServer)

    self._owner = owner
    self._serverChannel = serverChannel

    self._subscribers = {}

    self._cleaner = Cleaner.new()
    self._store = self._cleaner:give(Slick.Store.new(initial, self._serverChannel._module and require(self._serverChannel._module)))

    self.reduced = self._store.reduced
    self.changed = self._store.changed
    
    self.subscribed = self._cleaner:give(TrueSignal.new())
    self.unsubscribed = self._cleaner:give(TrueSignal.new())

    self._cleaner:give(self._store.reduced:connect(function(key, reducer, ...)
        self._serverChannel._serverSignal:fireClients(self:getSubscribers(), "dispatch", self._owner, key, reducer, ...)
    end))

    self._serverChannel._cleaner:set(owner, self)
    self._serverChannel.created:fire(owner, self)

    return self
end

function StaticStoreServer:getSubscribers()
    return table.clone(self._subscribers)
end

function StaticStoreServer:isSubscribed(player)
    return table.find(self._subscribers, player) ~= nil
end



function StaticStoreServer:subscribe(player)
    if self:isSubscribed(player) then
        return
    end

    table.insert(self._subscribers, player)

    self._serverChannel._serverSignal:fireClient(player, "static", self._owner, self._store:getState(), self._serverChannel._module)
    self.subscribed:fire(player)
end

function StaticStoreServer:unsubscribe(player)
    if not self:isSubscribed(player) then
        return
    end

    table.remove(self._subscribers, table.find(self._subscribers, player))

    self._serverChannel._serverSignal:fireClient(player, "unsubscribe", self._owner)
    self.unsubscribed:fire(player)
end




function StaticStoreServer:dispatch(key, reducer, ...)
    self._store:dispatch(key, reducer, ...)
end

function StaticStoreServer:getValue(key)
    return self._store:getValue(key)
end

function StaticStoreServer:getChangedSignal(key)
    return self._store:getChangedSignal(key)
end

function StaticStoreServer:getReducedSignal(key, reducer)
    return self._store:getReducedSignal(key, reducer)
end




function StaticStoreServer:destroy()
    for _, player in self:getSubscribers() do
        self:unsubscribe(player)
    end

    self._serverChannel.removed:fire(self._owner)

    self._cleaner:destroy()
    self.destroyed = true
end

return StaticStoreServer