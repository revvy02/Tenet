local Slick = require(script.Parent.Parent.Parent.Parent.Slick)
local Cleaner = require(script.Parent.Parent.Parent.Parent.Cleaner)
local Promise = require(script.Parent.Parent.Parent.Parent.Promise)
local TrueSignal = require(script.Parent.Parent.Parent.Parent.TrueSignal)

--[=[
    NonatomicChannelClient class

    @class NonatomicChannelClient
]=]
local NonatomicChannelClient = {}
NonatomicChannelClient.__index = NonatomicChannelClient

--[=[
    Creates a new NonatomicChannelClient

    @param reducers table
    @return NonatomicChannelClient

    @private
]=]
function NonatomicChannelClient._new(initial, reducers)
    local self = setmetatable({}, NonatomicChannelClient)

    self._cleaner = Cleaner.new()
    self._store = self._cleaner:give(Slick.Store.new(initial, reducers))

    self._loaded = {}

    self.changed = self._store.changed
    self.reduced = self._store.reduced

    self.streamed = self._cleaner:give(TrueSignal.new())
    self.unstreamed = self._cleaner:give(TrueSignal.new())

    return self
end

--[=[
    Used to dispatch to the store to change key values

    @param key any
    @param reducer string
    @param ... any

    @private
]=]
function NonatomicChannelClient:_dispatch(key, reducer, ...)
    self._store:dispatch(key, reducer, ...)
end

--[=[
    Used to load the key and resolve any pending loadedAsync promises

    @param key any
    @param value any
]=]
function NonatomicChannelClient:_stream(key, value)
    self._store:dispatch(key, "setValue", value)
    self._loaded[key] = true
    self.streamed:fire(key, value)
end

--[=[
    Used to unload the key

    @param key any
]=]
function NonatomicChannelClient:_unstream(key)
    self._store:dispatch(key, "setValue", nil)
    self._loaded[key] = nil
    self.unstreamed:fire(key)
end

--[=[
    Prepares the NonatomicChannelClient object for garbage collection

    @private
]=]
function NonatomicChannelClient:_destroy()
    self._cleaner:destroy()
end

--[=[
    Gets key value from store

    @key any
    @return any
]=]
function NonatomicChannelClient:getValue(key)
    return self._store:getValue(key)
end

--[=[
    Gets key changed signal

    @key any
    @return Signal
]=]
function NonatomicChannelClient:getChangedSignal(key)
    return self._store:getChangedSignal(key)
end

--[=[
    Gets key reduced signal

    @key any
    @return Signal
]=]
function NonatomicChannelClient:getReducedSignal(key, reducer)
    return self._store:getReducedSignal(key, reducer)
end

return NonatomicChannelClient