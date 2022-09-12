local Slick = require(script.Parent.Parent.Parent.Parent.Slick)
local Cleaner = require(script.Parent.Parent.Parent.Parent.Cleaner)
local Promise = require(script.Parent.Parent.Parent.Parent.Promise)
local TrueSignal = require(script.Parent.Parent.Parent.Parent.TrueSignal)

--[=[
    Client channel class for nonatomic state reception

    @class NonatomicChannelClient
]=]
local NonatomicChannelClient = {}
NonatomicChannelClient.__index = NonatomicChannelClient

--[=[
    Creates a new NonatomicChannelClient

    @param initial table
    @param reducers {[string]: () -> ()}
    @return NonatomicChannelClient

    @private
]=]
function NonatomicChannelClient._new(clientBroadcast, host, initial, reducers)
    local self = setmetatable({}, NonatomicChannelClient)

    self._clientBroadcast = clientBroadcast
    self._host = host

    self._cleaner = Cleaner.new()
    self._store = self._cleaner:give(Slick.Store.new(initial, reducers))

    self._loaded = {}

    --[=[
        Signal that gets fired once key in store is reduced

        @prop reduced TrueSignal
        @readonly
        @within NonatomicChannelClient
    ]=]
    self.reduced = self._store.reduced

    --[=[
        Signal that gets fired once key in store is changed

        @prop changed TrueSignal
        @readonly
        @within NonatomicChannelClient
    ]=]
    self.changed = self._store.changed

    --[=[
        Signal that gets fired once a key is streamed to the client

        @prop streamed TrueSignal
        @readonly
        @within NonatomicChannelServer
    ]=]
    self.streamed = self._cleaner:give(TrueSignal.new())

    --[=[
        Signal that gets fired once a key is unstreamed from the client

        @prop unstreamed TrueSignal
        @readonly
        @within NonatomicChannelServer
    ]=]
    self.unstreamed = self._cleaner:give(TrueSignal.new())

    self._clientBroadcast._hosts = table.clone(self._clientBroadcast._hosts)
    table.insert(self._clientBroadcast._hosts, host)
    table.freeze(self._clientBroadcast._hosts)

    return self
end

--[=[
    Used to dispatch to the store to change key values

    @param key any
    @param reducer string
    @param ... any

    @private
]=]
function NonatomicChannelClient:_dispatch(reducer, key, ...)
    self._store:dispatch(reducer, key, ...)
end

--[=[
    Used to load the key and resolve any pending loadedAsync promises

    @param key any
    @param value any

    @private
]=]
function NonatomicChannelClient:_stream(key, value)
    self._store:dispatch("setValue", key, value)
    self._loaded[key] = true
    self.streamed:fire(key, value)
end

--[=[
    Used to unload the key

    @param key any

    @private
]=]
function NonatomicChannelClient:_unstream(key)
    self._store:dispatch("setValue", key, nil)
    self._loaded[key] = nil
    self.unstreamed:fire(key)
end

--[=[
    Prepares the NonatomicChannelClient object for garbage collection

    @private
]=]
function NonatomicChannelClient:_destroy()
    self._clientBroadcast._hosts = table.clone(self._clientBroadcast._hosts)
    table.remove(self._clientBroadcast._hosts, table.find(self._clientBroadcast._hosts, self._host))
    table.freeze(self._clientBroadcast._hosts)

    self._cleaner:destroy()
end

--[=[
    Gets the key value from store

    @param key any
    @return any
]=]
function NonatomicChannelClient:getValue(key)
    return self._store:getValue(key)
end

--[=[
    Gets the signal that's fired when the key changes

    @param key any
    @return TrueSignal
]=]
function NonatomicChannelClient:getChangedSignal(key)
    return self._store:getChangedSignal(key)
end

--[=[
    Gets the signal that's fired when the key changes

    @param key any
    @param reducer string
    @return TrueSignal
]=]
function NonatomicChannelClient:getReducedSignal(reducer, key)
    return self._store:getReducedSignal(reducer, key)
end

return NonatomicChannelClient