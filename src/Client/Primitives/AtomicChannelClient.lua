local Slick = require(script.Parent.Parent.Parent.Slick)

local AtomicChannelClient = {}
AtomicChannelClient.__index = AtomicChannelClient

--[=[

]=]
function AtomicChannelClient._new(initial, reducers)
    local self = setmetatable({}, AtomicChannelClient)

    self._store = Slick.Store.new(initial, reducers)

    self.reduced = self._store.reduced
    self.changed = self._store.changed

    return self
end

function AtomicChannelClient:_dispatch(key, reducer, ...)
    self._store:dispatch(key, reducer, ...)
end

function AtomicChannelClient:_destroy()
    self._store:destroy()
    self.destroyed = true
end




function AtomicChannelClient:getValue(key)
    return self._store:getValue(key)
end

function AtomicChannelClient:getChangedSignal(key)
    return self._store:getChangedSignal(key)
end

function AtomicChannelClient:getReducedSignal(key, reducer)
    return self._store:getReducedSignal(key, reducer)
end





return AtomicChannelClient