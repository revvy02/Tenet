local Slick = require(script.Parent.Parent.Parent.Slick)
local Cleaner = require(script.Parent.Parent.Parent.Cleaner)
local Promise = require(script.Parent.Parent.Parent.Promise)

--[=[
    DynamicStore class

    @class DynamicStore
]=]
local DynamicStore = {}
DynamicStore.__index = DynamicStore


--[=[
    Creates a new DynamicStore

    @param reducers table
    @return DynamicStore
]=]
function DynamicStore.new(reducers)
    local self = setmetatable({}, DynamicStore)

    self._cleaner = Cleaner.new()
    self._store = self._cleaner:add(Slick.Store.new())

    self._loaded = {}

    self.changed = self._store.changed
    self.reduced = self._store.reduced

    self.loaded = self._cleaner:add(Slick.Signal.new())
    self.unloaded = self._cleaner:add(Slick.Signal.new())

    if reducers then
        self:setReducers(reducers)
    end

    return self
end

--[=[
    Returns whether or not the passed argument is a DynamicStore

    @param obj any
    @return bool
]=]
function DynamicStore.is(obj)
    return typeof(obj) == "table" and getmetatable(obj) == DynamicStore
end

--[=[
    Gets key value from store

    @key any
    @return any
]=]
function DynamicStore:get(key)
    return self._store:get(key)
end

--[=[
    Gets key changed signal

    @key any
    @return Signal
]=]
function DynamicStore:getChangedSignal(key)
    return self._store:getChangedSignal(key)
end

--[=[
    Gets key reduced signal

    @key any
    @return Signal
]=]
function DynamicStore:getReducedSignal(key, reducer)
    return self._store:getReducedSignal(key, reducer)
end

--[=[
    Returns a promise that resolves once the key value is loaded

    @key any
    @return Promise
]=]
function DynamicStore:loadedAsync(key)
    if self._loaded[key] == true then
        return Promise.resolve()
    end

    return Promise.fromEvent(self.loaded, function(loadedKey)
        return loadedKey == key
    end)
end

--[=[
    Used to dispatch to the store to change key values

    @param key any
    @param reducer string
    @param ... any
]=]
function DynamicStore:dispatch(key, reducer, ...)
    self._store:dispatch(key, reducer, ...)
end

--[=[
    Used to set the reducers module

    @param module ModuleScript
]=]
function DynamicStore:setReducers(reducers)
    self._store:setReducers(reducers)
end

--[=[
    Used to load the key and resolve any pending loadedAsync promises

    @param key any
    @param value any
]=]
function DynamicStore:load(key, value)
    self._store:dispatch(key, "setValue", value)
    self._loaded[key] = true
    self.loaded:fire(key)
end

--[=[
    Used to unload the key

    @param key any
]=]
function DynamicStore:unload(key)
    self._store:dispatch(key, "setValue", nil)
    self._loaded[key] = nil
    self.unloaded:fire(key)
end

--[=[
    Prepares the DynamicStore object for garbage collection
]=]
function DynamicStore:destroy()
    self._cleaner:destroy()
    self.destroyed = true
end




return DynamicStore