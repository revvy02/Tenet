local Slick = require(script.Parent.Parent.Parent.Parent.Slick)
local Cleaner = require(script.Parent.Parent.Parent.Parent.Cleaner)
local TrueSignal = require(script.Parent.Parent.Parent.Parent.TrueSignal)

--[=[
    Server channel class for atomic state transmission

    @class AtomicChannelServer
]=]
local AtomicChannelServer = {}
AtomicChannelServer.__index = AtomicChannelServer

--[=[
    Unsubscribes all players and prepares the channel for garbage collection
    
    @private
]=]
function AtomicChannelServer:_destroy()
    self._serverBroadcast._hosts = table.clone(self._serverBroadcast._hosts)
    table.remove(self._serverBroadcast._hosts, table.find(self._serverBroadcast._hosts, self._host))
    table.freeze(self._serverBroadcast._hosts)

    for _, player in self:getSubscribers() do
        self:unsubscribe(player)
    end

    self._serverBroadcast.removed:fire(self._host)

    self._cleaner:destroy()
    self.destroyed = true
end

--[=[
    Constructs a new AtomicChannelServer

    @param serverBroadcast ServerBroadcast
    @param host any
    @param initialState table?
    @param reducersModule ModuleScript?
    @return AtomicChannelServer

    @private
]=]
function AtomicChannelServer._new(serverBroadcast, host, initialState, reducersModule)
    assert(serverBroadcast._channelCleaner:get(host) == nil, string.format("Cannot create more than one channel for host (%s)", tostring(host)))

    local self = setmetatable({}, AtomicChannelServer)
    
    self._serverBroadcast = serverBroadcast

    self._host = host
    self._reducersModule = reducersModule or self._serverBroadcast._defaultReducersModule

    self._subscribers = {}

    self._cleaner = Cleaner.new()

    self._store = self._cleaner:give(Slick.Store.new(initialState and table.clone(initialState), require(self._reducersModule)))

    --[=[
        Signal that gets fired once key in store is reduced

        @prop reduced TrueSignal
        @readonly
        @within AtomicChannelServer
    ]=]
    self.reduced = self._store.reduced

    --[=[
        Signal that gets fired once key in store is changed

        @prop changed TrueSignal
        @readonly
        @within AtomicChannelServer
    ]=]
    self.changed = self._store.changed
    
    --[=[
        Signal that gets fired once a player is subscribed to a channel

        @prop subscribed TrueSignal
        @readonly
        @within AtomicChannelServer
    ]=]
    self.subscribed = self._cleaner:give(TrueSignal.new())

    --[=[
        Signal that gets fired once a player is unsubscribed to a channel

        @prop unsubscribed TrueSignal
        @readonly
        @within AtomicChannelServer
    ]=]
    self.unsubscribed = self._cleaner:give(TrueSignal.new())

    self._cleaner:give(self._store.reduced:connect(function(reducer, key, ...)
        self._serverBroadcast._serverSignal:fireClients(self:getSubscribers(), "dispatch", self._host, reducer, key, ...)
    end))

    self._serverBroadcast._hosts = table.clone(self._serverBroadcast._hosts)
    table.insert(self._serverBroadcast._hosts, host)
    table.freeze(self._serverBroadcast._hosts)

    self._serverBroadcast._channelCleaner:set(host, self, AtomicChannelServer._destroy)
    self._serverBroadcast.created:fire(host, self)

    return self
end

--[=[
    Returns a list of players subscribed to the channel

    @return {...Players}
]=]
function AtomicChannelServer:getSubscribers()
    return table.clone(self._subscribers)
end

--[=[
    Returns whether or not the passed player is subscribed to the channel

    @param player Player
    @return boolean
]=]
function AtomicChannelServer:isSubscribed(player)
    return table.find(self._subscribers, player) ~= nil
end

--[=[
    Subscribes the player to the channel

    @param player Player
]=]
function AtomicChannelServer:subscribe(player)
    if self:isSubscribed(player) then
        return
    end

    table.insert(self._subscribers, player)

    self._serverBroadcast._serverSignal:fireClient(player, "atomic", self._host, self._store:getState(), self._reducersModule)
    self.subscribed:fire(player)
end

--[=[
    Unsubscribes the player to the channel

    @param player Player
]=]
function AtomicChannelServer:unsubscribe(player)
    if not self:isSubscribed(player) then
        return
    end

    table.remove(self._subscribers, table.find(self._subscribers, player))

    self._serverBroadcast._serverSignal:fireClient(player, "unsubscribe", self._host)
    self.unsubscribed:fire(player)
end

--[=[
    Dispatches a reducer on the key

    @param key any
    @param reducer string
    @param ... any
]=]
function AtomicChannelServer:dispatch(reducer, key, ...)
    self._store:dispatch(reducer, key, ...)
end

--[=[
    Gets the value of the key

    @param key any
    @return any
]=]
function AtomicChannelServer:getValue(key)
    return self._store:getValue(key)
end

--[=[
    Gets a signal that will fire when the value of the key changes

    @param key any
    @return TrueSignal
]=]
function AtomicChannelServer:getChangedSignal(key)
    return self._store:getChangedSignal(key)
end

--[=[
    Gets a signal that will fire when the value of the key is reduced

    @param key any
    @param reducer string
    @return TrueSignal
]=]
function AtomicChannelServer:getReducedSignal(reducer, key)
    return self._store:getReducedSignal(reducer, key)
end

return AtomicChannelServer