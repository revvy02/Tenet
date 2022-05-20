local Cleaner = require(script.Parent.Parent.Parent.Cleaner)
local Slick = require(script.Parent.Parent.Parent.Slick)

local StaticStore = {}
StaticStore.__index = StaticStore

function StaticStore.new(module, state)
    local self = setmetatable({}, StaticStore)

    self._cleaner = Cleaner.new()
    self._store = self._cleaner:add(Slick.Store.new(state))

    self.changed = self._store.changed
    self.reduced = self._store.reduced

    self:_setReducers(module)

    return self
end


function StaticStore:get(key)
    return self._store:get(key)
end

function StaticStore:getChangedSignal(key)
    return self._store:getChangedSignal(key)
end

function StaticStore:getReducedSignal(key, reducer)
    return self._store:getReducedSignal(key, reducer)
end



function StaticStore:_dispatch(key, reducer, ...)
    self._store:dispatch(key, reducer, ...)
end

function StaticStore:_setReducers(module)
    self._store:setReducers(module)
end



function StaticStore:destroy()
    self._cleaner:destroy()
end

return StaticStore