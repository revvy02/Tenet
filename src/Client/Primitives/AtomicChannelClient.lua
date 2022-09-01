local Slick = require(script.Parent.Parent.Parent.Parent.Slick)

local AtomicChannelClient = {}
AtomicChannelClient.__index = AtomicChannelClient

--[=[
    Creates a new AtomicChannelClient

    @param reducers table
    @return AtomicChannelClient

    @private
]=]
function AtomicChannelClient._new(initial, reducers)
    local self = setmetatable({}, AtomicChannelClient)

    self._store = Slick.Store.new(initial, reducers)

    self.reduced = self._store.reduced
    self.changed = self._store.changed

    return self
end

--[=[
    Used to dispatch to the store to change key values

    @param key any
    @param reducer string
    @param ... any

    @private
]=]
function AtomicChannelClient:_dispatch(key, reducer, ...)
    self._store:dispatch(key, reducer, ...)
end

--[=[
    Prepares the AtomicChannelClient object for garbage collection

    @private
]=]
function AtomicChannelClient:_destroy()
    self._store:destroy()
end

--[=[
    Gets the key value from store

    @key any
    @return any
]=]
function AtomicChannelClient:getValue(key)
    return self._store:getValue(key)
end

--[=[
    Gets the signal that's fired when the key changes

    @key any
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
function AtomicChannelClient:getReducedSignal(key, reducer)
    return self._store:getReducedSignal(key, reducer)
end

return AtomicChannelClient