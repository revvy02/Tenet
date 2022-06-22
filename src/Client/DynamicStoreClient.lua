local Slick = require(script.Parent.Parent.Parent.Slick)
local Cleaner = require(script.Parent.Parent.Parent.Cleaner)
local Promise = require(script.Parent.Parent.Parent.Promise)
local TrueSignal = require(script.Parent.Parent.Parent.TrueSignal)

--[=[
    DynamicStoreClient class

    @class DynamicStoreClient
]=]
local DynamicStoreClient = {}
DynamicStoreClient.__index = DynamicStoreClient

--[=[
    Creates a new DynamicStoreClient

    @param reducers table
    @return DynamicStoreClient

    @private
]=]
function DynamicStoreClient._new(initial, reducers)
    local self = setmetatable({}, DynamicStoreClient)

    self._cleaner = Cleaner.new()
    self._store = self._cleaner:give(Slick.Store.new(initial, reducers))

    self._loaded = {}

    self.changed = self._store.changed
    self.reduced = self._store.reduced

    self.loaded = self._cleaner:give(TrueSignal.new())
    self.unloaded = self._cleaner:give(TrueSignal.new())

    return self
end

--[=[
    Used to dispatch to the store to change key values

    @param key any
    @param reducer string
    @param ... any

    @private
]=]
function DynamicStoreClient:_dispatch(key, reducer, ...)
    self._store:dispatch(key, reducer, ...)
end

--[=[
    Used to load the key and resolve any pending loadedAsync promises

    @param key any
    @param value any
]=]
function DynamicStoreClient:_load(key, value)
    self._store:dispatch(key, "setValue", value)
    self._loaded[key] = true
    self.loaded:fire(key)
end

--[=[
    Used to unload the key

    @param key any
]=]
function DynamicStoreClient:_unload(key)
    self._store:dispatch(key, "setValue", nil)
    self._loaded[key] = nil
    self.unloaded:fire(key)
end

--[=[
    Prepares the DynamicStoreClient object for garbage collection

    @private
]=]
function DynamicStoreClient:_destroy()
    self._cleaner:destroy()
    self.destroyed = true
end

--[=[
    Gets key value from store

    @key any
    @return any
]=]
function DynamicStoreClient:getValue(key)
    return self._store:getValue(key)
end

--[=[
    Gets key changed signal

    @key any
    @return Signal
]=]
function DynamicStoreClient:getChangedSignal(key)
    return self._store:getChangedSignal(key)
end

--[=[
    Gets key reduced signal

    @key any
    @return Signal
]=]
function DynamicStoreClient:getReducedSignal(key, reducer)
    return self._store:getReducedSignal(key, reducer)
end

--[=[
    Returns a promise that resolves once the key value is loaded

    @key any
    @return Promise
]=]
function DynamicStoreClient:loadedAsync(key)
    if self._loaded[key] == true then
        return Promise.resolve()
    end

    return Promise.fromEvent(self.loaded, function(loadedKey)
        return loadedKey == key
    end)
end

return DynamicStoreClient