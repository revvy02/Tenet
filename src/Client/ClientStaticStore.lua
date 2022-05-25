local Promise = require(script.Parent.Parent.Parent.Promise)
local Cleaner = require(script.Parent.Parent.Parent.Cleaner)
local Slick = require(script.Parent.Parent.Parent.Slick)

local ClientSignal = require(script.Parent.ClientSignal)

local actionHandlers = {
    dispatch = function(store, key, reducer, ...)
        store:dispatch(key, reducer, ...)
    end,

    setReducers = function(store, module)
        store:setReducers(require(module))
    end,
}

--[=[
    ClientStaticStore class

    @class ClientStaticStore
]=]
local ClientStaticStore = {}
ClientStaticStore.__index = ClientStaticStore

--[=[
    Creates a new ClientStaticStore

    @param remotes table
    @return ClientStaticStore
]=]
function ClientStaticStore.new(remotes)
    local self = setmetatable({}, ClientStaticStore)

    self._cleaner = Cleaner.new()

    self._clientSignal = self._cleaner:add(ClientSignal.new(remotes))

    self._store = self._cleaner:add(Slick.Store.new())

    self._cleaner:add(self._clientSignal:connect(function(action, ...)
        actionHandlers[action](self._store, ...)
    end))

    return self
end

--[=[
    Returns whether or not the passed argument is a ClientStaticStore or not

    @param obj any
    @return bool
]=]
function ClientStaticStore.is(obj)
    return typeof(obj) == "table" and getmetatable(obj) == ClientStaticStore
end

--[=[
    Gets the internal dynamicStore

    @return StaticStore
]=]
function ClientStaticStore:getStore()
    return self._store
end

--[=[
    Prepares the ClientStaticStore instance for garbage collection
]=]
function ClientStaticStore:destroy()
    self._cleaner:destroy()
    self.destroyed = true
end

return ClientStaticStore