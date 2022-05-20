local Slick = require(script.Parent.Parent.Parent.Slick)
local Cleaner = require(script.Parent.Parent.Parent.Cleaner)
local Promise = require(script.Parent.Parent.Parent.Promise)


local ChannelStore = {}
ChannelStore.__index = ChannelStore



function ChannelStore.new(module)
    local self = setmetatable({}, ChannelStore)

    self._cleaner = Cleaner.new()
    self._store = self._cleaner:add(Slick.Store.new())
    self._loaded = self._cleaner:add(Slick.Store.new())

    self.changed = self._store.changed
    self.reduced = self._store.reduced

    self:_setReducers(module)

    return self
end






function ChannelStore:get(key)
    return self._store:get(key)
end

function ChannelStore:getChangedSignal(key)
    return self._store:getChangedSignal(key)
end

function ChannelStore:getReducedSignal(key, reducer)
    return self._store:getReducedSignal(key, reducer)
end

function ChannelStore:loaded(key)
    if self._loaded:get(key) == true then
        return Promise.resolve(self._store:get(key))
    end

    return Promise.fromEvent(self._loaded.changed, function(reducedKey, bool)
        return reducedKey == key and bool == true
    end):andThen(function()
        return self._store:get(key)
    end)
end



function ChannelStore:_dispatch(key, reducer, ...)
    self._channelStore:_dispatch(key, reducer, ...)
end

function ChannelStore:_setReducers(module)
    self._store:setReducers(require(module))
end

function ChannelStore:_load(key, value)
    self._store:dispatch(key, "setValue", value)
    self._loaded:dispatch(key, "setValue", true)
end

function ChannelStore:_unload(key)
    self._store:dispatch(key, "setValue", nil)
    self._loaded:dispatch(key, "setValue", nil)
end





function ChannelStore:destroy()
    self._cleaner:destroy()
end




return ChannelStore