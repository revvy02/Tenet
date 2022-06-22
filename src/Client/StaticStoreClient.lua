local Slick = require(script.Parent.Parent.Parent.Slick)

local StaticStoreClient = {}
StaticStoreClient.__index = StaticStoreClient

--[=[

]=]
function StaticStoreClient._new(initial, reducers)
    local self = setmetatable({}, StaticStoreClient)

    self._store = Slick.Store.new(initial, reducers)

    self.reduced = self._store.reduced
    self.changed = self._store.changed

    return self
end

function StaticStoreClient:_dispatch(key, reducer, ...)
    self._store:dispatch(key, reducer, ...)
end

function StaticStoreClient:_destroy()
    self._store:destroy()
    self.destroyed = true
end




function StaticStoreClient:getValue(key)
    return self._store:getValue(key)
end

function StaticStoreClient:getChangedSignal(key)
    return self._store:getChangedSignal(key)
end

function StaticStoreClient:getReducedSignal(key, reducer)
    return self._store:getReducedSignal(key, reducer)
end





return StaticStoreClient