local Slick = require(script.Parent.Parent.Parent.Slick)
local Cleaner = require(script.Parent.Parent.Parent.Cleaner)

local NetworkSignal = require(script.Parent.NetworkSignal)
local NetworkCallback = require(script.Parent.NetworkCallback)

local NetworkStaticStore = {}
NetworkStaticStore.__index = NetworkStaticStore


function NetworkStaticStore.new(remoteEvent, remoteFunction)
    local self = setmetatable({}, NetworkStaticStore)

    self._cleaner = Cleaner.new()
    self._networkSignal = self._cleaner:add(NetworkSignal.new(remoteEvent))
    self._networkCallback = self._cleaner:add(NetworkCallback.new(remoteFunction))

    self._store = self._cleaner:add(Slick.Store.new())

    self._networkCallback:setServerCallback(function(_, action)
        if action == "fetch" then
            return self._store:getState(), self._reducers
        end
    end)

    self._cleaner:add(self._store.reduced:connect(function(key, reducer, ...)
        self._networkSignal:fireAllClients(key, reducer, ...)
    end))

    return self
end




function NetworkStaticStore:dispatch(key, reducer, ...)
    self._store:dispatch(key, reducer, ...)
end

function NetworkStaticStore:setReducers(module)
    self._reducers = module
    self._networkSignal:fireAllClients("setReducers", module)
end

function NetworkStaticStore:getChangedSignal(key)
    return self._store:getChangedSignal(key)
end

function NetworkStaticStore:getReducedSignal(key, reducer)
    return self._store:getReducedSignal(key, reducer)
end




function NetworkStaticStore:destroy()
    self._cleaner:destroy()
end


return NetworkStaticStore