local Promise = require(script.Parent.Parent.Parent.Promise)
local Cleaner = require(script.Parent.Parent.Parent.Cleaner)
local Slick = require(script.Parent.Parent.Parent.Slick)

local DynamicStore = require(script.Parent.DynamicStore)
local ClientSignal = require(script.Parent.ClientSignal)

local actionHandlers = {
    dispatch = function(store, key, reducer, ...)
        store:dispatch(key, reducer, ...)
    end,

    setReducers = function(store, module)
        store:setReducers(require(module))
    end,

    load = function(store, key, value)
        store:load(key, value)
    end,

    unload = function(store, key)
        store:unload(key)
    end,
}

--[=[
    ClientDynamicStore class

    @class ClientDynamicStore
]=]
local ClientDynamicStore = {}
ClientDynamicStore.__index = ClientDynamicStore

--[=[
    Creates a new ClientDynamicStore

    @param remotes table
    @return ClientDynamicStore
]=]
function ClientDynamicStore.new(remotes)
    local self = setmetatable({}, ClientDynamicStore)

    self._cleaner = Cleaner.new()

    self._clientSignal = self._cleaner:add(ClientSignal.new(remotes))

    self._store = self._cleaner:add(DynamicStore.new())

    self._cleaner:add(self._clientSignal:connect(function(action, ...)
        actionHandlers[action](self._store, ...)
    end))

    return self
end

--[=[
    Returns whether or not the passed argument is a ClientDynamicStore or not

    @param obj any
    @return bool
]=]
function ClientDynamicStore.is(obj)
    return typeof(obj) == "table" and getmetatable(obj) == ClientDynamicStore
end

--[=[
    Gets the internal dynamicStore

    @return DynamicStore
]=]
function ClientDynamicStore:getStore()
    return self._store
end

--[=[
    Prepares the ClientDynamicStore instance for garbage collection
]=]
function ClientDynamicStore:destroy()
    self._cleaner:destroy()
    self.destroyed = true
end

return ClientDynamicStore