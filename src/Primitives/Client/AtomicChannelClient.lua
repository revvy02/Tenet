local Slick = require(script.Parent.Parent.Parent.Parent.Slick)

--[=[
    Client channel class for atomic state reception

    @class AtomicChannelClient
]=]
local AtomicChannelClient = {}
AtomicChannelClient.__index = AtomicChannelClient

--[=[
    Creates a new AtomicChannelClient

    @param initial table?
    @param reducers table?
    @return AtomicChannelClient

    @private
]=]
function AtomicChannelClient._new(clientBroadcast, host, initial, reducers)
    local self = setmetatable({}, AtomicChannelClient)

    self._clientBroadcast = clientBroadcast
    self._host = host

    self._store = Slick.Store.new(initial, reducers)

    --[=[
        Signal that gets fired once key in store is reduced

        @prop reduced TrueSignal
        @readonly
        @within AtomicChannelClient
    ]=]
    self.reduced = self._store.reduced

    --[=[
        Signal that gets fired once key in store is changed

        @prop changed TrueSignal
        @readonly
        @within AtomicChannelClient
    ]=]
    self.changed = self._store.changed

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
function AtomicChannelClient:_dispatch(reducer, key, ...)
    self._store:dispatch(reducer, key, ...)
end

--[=[
    Prepares the AtomicChannelClient object for garbage collection

    @private
]=]
function AtomicChannelClient:_destroy()
    self._clientBroadcast._hosts = table.clone(self._clientBroadcast._hosts)
    table.remove(self._clientBroadcast._hosts, table.find(self._clientBroadcast._hosts, self._host))
    table.freeze(self._clientBroadcast._hosts)

    self._store:destroy()
end

--[=[
    Gets the key value from store

    @param key any
    @return any
]=]
function AtomicChannelClient:getValue(key)
    return self._store:getValue(key)
end

--[=[
    Gets the signal that's fired when the key changes

    @param key any
    @return TrueSignal
]=]
function AtomicChannelClient:getChangedSignal(key)
    return self._store:getChangedSignal(key)
end

--[=[
    Gets a signal that will fire when the value of the key is reduced

    @param key any
    @param reducer string
    @return TrueSignal
]=]
function AtomicChannelClient:getReducedSignal(reducer, key)
    return self._store:getReducedSignal(reducer, key)
end

return AtomicChannelClient