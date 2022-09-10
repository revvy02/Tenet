local Slick = require(script.Parent.Parent.Parent.Parent.Slick)
local Cleaner = require(script.Parent.Parent.Parent.Parent.Cleaner)
local TrueSignal = require(script.Parent.Parent.Parent.Parent.TrueSignal)

--[=[
    Server channel class for nonatomic state transmission

    @class NonatomicChannelServer
]=]
local NonatomicChannelServer = {}
NonatomicChannelServer.__index = NonatomicChannelServer

--[=[
    Returns a player perspective snapshot of the state

    @param player Player
    @return table

    @private
]=]
function NonatomicChannelServer:_getSnapshot(player)
    local state = {}

    for key in self._streamers do
        if self:isStreamed(key, player) then
            state[key] = self:getValue(key)
        end
    end

    return state
end

--[=[
    Unsubscribes all players and prepares the channel for garbage collection
    
    @private
]=]
function NonatomicChannelServer:_destroy()
    for _, player in self:getSubscribers() do
        self:unsubscribe(player)
    end

    table.clear(self._streamers)

    self._serverBroadcast.removed:fire(self._host)

    self._cleaner:destroy()
end

--[=[
    Constructs a new NonatomicChannelServer

    @param serverBroadcast ServerBroadcast
    @param host any
    @param initialState table?
    @param reducersModule ModuleScript?
    @return NonatomicChannelServer

    @private
]=]
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

    --[=[
        Signal that gets fired once key in store is reduced

        @prop reduced TrueSignal
        @readonly
        @within NonatomicChannelServer
    ]=]
    self.reduced = self._store.reduced

    --[=[
        Signal that gets fired once key in store is changed

        @prop changed TrueSignal
        @readonly
        @within NonatomicChannelServer
    ]=]
    self.changed = self._store.changed
    
    --[=[
        Signal that gets fired once a player is subscribed to a channel

        @prop subscribed TrueSignal
        @readonly
        @within NonatomicChannelServer
    ]=]
    self.subscribed = self._cleaner:give(TrueSignal.new())

    --[=[
        Signal that gets fired once a player is unsubscribed to a channel

        @prop unsubscribed TrueSignal
        @readonly
        @within NonatomicChannelServer
    ]=]
    self.unsubscribed = self._cleaner:give(TrueSignal.new())

    --[=[
        Signal that gets fired once a key is streamed to a player

        @prop streamed TrueSignal
        @readonly
        @within NonatomicChannelServer
    ]=]
    self.streamed = self._cleaner:give(TrueSignal.new())

    --[=[
        Signal that gets fired once a key is unstreamed from a player

        @prop unstreamed TrueSignal
        @readonly
        @within NonatomicChannelServer
    ]=]
    self.unstreamed = self._cleaner:give(TrueSignal.new())

    self._cleaner:give(self._store.reduced:connect(function(reducer, key, ...)
        self._serverBroadcast._serverSignal:fireClients(self:getStreamedSubscribers(key), "dispatch", self._host, reducer, key, ...)
    end))

    self._serverBroadcast._channelCleaner:set(host, self, NonatomicChannelServer._destroy)
    self._serverBroadcast.created:fire(host, self)

    return self
end

--[=[
    Returns a list of players subscribed to the channel

    @return {...Players}
]=]
function NonatomicChannelServer:getSubscribers()
    return table.clone(self._subscribers)
end

--[=[
    Returns a list of players to stream the key to

    @param key any
    @return {...Players}
]=]
function NonatomicChannelServer:getStreamers(key)
    return self._streamers[key] and table.clone(self._streamers[key]) or {}
end

--[=[
    Returns a list of players subscribed to the channel that the key is being streamed to

    @param key any
    @return {...Players}
]=]
function NonatomicChannelServer:getStreamedSubscribers(key)
    local list = {}

    for _, player in self._subscribers do
        if self:isStreamed(key, player) then
            table.insert(list, player)
        end
    end

    return list
end

--[=[
    Returns whether or not the passed player is subscribed to the channel

    @param player Player
    @return boolean
]=]
function NonatomicChannelServer:isSubscribed(player)
    return table.find(self._subscribers, player) ~= nil
end

--[=[
    Returns whether or not the channel is streaming the key to the player

    @param key any
    @param player Player
    @return boolean
]=]
function NonatomicChannelServer:isStreamed(key, player)
    return self._streamers[key] and table.find(self._streamers[key], player) ~= nil
end

--[=[
    Subscribes the player to the channel

    @param player Player
    @return boolean
]=]
function NonatomicChannelServer:subscribe(player)
    if self:isSubscribed(player) then
        return
    end

    table.insert(self._subscribers, player)

    self._serverBroadcast._serverSignal:fireClient(player, "nonatomic", self._host, self:_getSnapshot(player), self._reducersModule)
    self.subscribed:fire(player)
end

--[=[
    Subscribes the player to the channel

    @param player Player
    @return boolean
]=]
function NonatomicChannelServer:unsubscribe(player)
    if not self:isSubscribed(player) then
        return
    end

    table.remove(self._subscribers, table.find(self._subscribers, player))

    self._serverBroadcast._serverSignal:fireClient(player, "unsubscribe", self._host)
    self.unsubscribed:fire(player)
end

--[=[
    Streams the key to the player if or when they are subscribed

    @param key any
    @param player Player
]=]
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

--[=[
    Unstreams the key from the player if they're subscribed

    @param key any
    @param player Player
]=]
function NonatomicChannelServer:unstream(key, player)
    if not self:isStreamed(key, player) then
        return
    end

    local list = self._streamers[key]
    table.remove(list, table.find(list, player))

    self.unstreamed:fire(key, player)

    if not self:isSubscribed(player) then
        return
    end

    self._serverBroadcast._serverSignal:fireClient(player, "unstream", self._host, key)
end

--[=[
    Dispatches a reducer on the key

    @param key any
    @param reducer string
    @param ... any
]=]
function NonatomicChannelServer:dispatch(reducer, key, ...)
    self._store:dispatch(reducer, key, ...)
end

--[=[
    Gets the value of the key

    @param key any
    @return any
]=]
function NonatomicChannelServer:getValue(key)
    return self._store:getValue(key)
end

--[=[
    Gets a signal that will fire when the value of the key changes

    @param key any
    @return TrueSignal
]=]
function NonatomicChannelServer:getChangedSignal(key)
    return self._store:getChangedSignal(key)
end

--[=[
    Gets a signal that will fire when the value of the key is reduced

    @param key any
    @param reducer string
    @return TrueSignal
]=]
function NonatomicChannelServer:getReducedSignal(reducer, key)
    return self._store:getReducedSignal(reducer, key)
end

return NonatomicChannelServer