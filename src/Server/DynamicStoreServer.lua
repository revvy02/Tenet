local DynamicStoreServer = {}
DynamicStoreServer.__index = DynamicStore

function DynamicStoreServer.new(serverSignal, owner, initial, reducers)
    local self = setmetatable({}, DynamicStore)

    self._watchers = {}
    self._subscribers = {}

    self._owner = owner
    self._serverSignal = serverSignal

    self._cleaner = Cleaner.new()

    self._store = self._cleaner:give(Slick.Store.new(initial, reducers))

    self.reduced = self._store.reduced
    self.changed = self._store.changed

    self._cleaner:give(self._store.reduced:connect(function(key, reducer, ...)
        self._serverSignal:fireClients(self:getWatchingSubscribers(key), "dispatch", self._owner, key, reducer, ...)
    end))

    self._cleaner:give(function()
        self._serverSignal:fireClients(self:getWatchers(), "unstream", self._owner)
    end)

    return self
end


function DynamicStoreClient:subscribed(key, player)
    local list = self._subscribers[key]

    if list and table.find(list, player) then
        return true
    else
        return false
    end
end

function DynamicStoreClient:watching(player)
    return table.find(self._watchers, player) ~= nil
end




function DynamicStoreClient:subscribe(key, player)
    if self:subscribed(key, player) then
        return
    end

    local list = self._subscribers[key]

    if not list then
        list = {}
        self._subscribers[key] = list
    end

    table.insert(list, player)
end

function DynamicStoreServer:unsubscribe(key, player)
    if not self:subscribed(key, player) then
        return
    end

    local list = self._subscribers[key]

    table.remove(list, table.find(list, player))
end

function DynamicStoreServer:getSubscribers(key)
    return self._subscribers[key]
end

function DynamicStoreServer:getWatchingSubscribers(key)
    local list = {}

    for _, player in pairs(self:getSubscribers(key)) do
        if self:watching(player) then
            table.insert(list, player)
        end
    end

    return list
end

function DynamicStoreServer:getWatchers()
    return self._watchers
end



function DynamicStoreServer:setReducers(module)
    self._reducersModule = module
    self._store:setReducers(require(module))
    self._serverSignal:fireClients(self:getWatchers(), "setReducers", self._owner, module)
end

function DynamicStoreServer:stream(player)
    if self:watching(player) then
        return
    end

    table.insert(self._watchers, player)

    self._serverSignal:fireClient(player, "stream", self._owner, self:getState(), self._reducersModule)
end

function DynamicStoreServer:unstream(player)
    if not self:watching(player) then
        return
    end

    table.remove(self._watchers, table.find(self._watchers, player))

    self._serverSignal:fireClient(player, "unstream", self._owner)
end




function DynamicStoreServer:dispatch(key, reducer, ...)
    self._store:dispatch(key, reducer, ...)
end

function DynamicStoreServer:getValue(key)
    return self._store:getValue(key)
end

function DynamicStoreServer:getState()
    return self._store:getState()
end

function DynamicStoreServer:getChangedSignal(key)
    return self._store:getChangedSignal(key)
end

function DynamicStoreServer:getReducedSignal(key)
    return self._store:getReducedSignal(key)
end




function DynamicStoreServer:destroy()
    self._cleaner:destroy()
end

return DynamicStoreServer