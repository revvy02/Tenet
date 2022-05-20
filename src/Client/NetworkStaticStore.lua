local Slick = require(script.Parent.Parent.Parent.Slick)
local Cleaner = require(script.Parent.Parent.Parent.Cleaner)

local NetworkSignal = require(script.Parent.NetworkSignal)
local NetworkCallback = require(script.Parent.NetworkCallback)
local StaticStore = require(script.Parent.StaticStore)

local NetworkStaticStore = {}
NetworkStaticStore.__index = NetworkStaticStore

function NetworkStaticStore.new(options)
    local self = setmetatable({}, NetworkStaticStore)

    self._cleaner = Cleaner.new()
    self._networkSignal = self._cleaner:add(NetworkSignal.new(options.remoteEvent))
    self._networkCallback = self._cleaner:add(NetworkCallback.new(options.remoteEvent))

    self._staticStore = self._cleaner:add(StaticStore.new(self._networkCallback:callServer("fetch"):await()))

    self.changed = self._store.changed
    self.reduced = self._store.reduced

    self._cleaner:add(self._networkSignal:connect(function(action, key, reducer, ...)
        if action == "dispatch" then
            self._staticStore:_dispatch(key, reducer, ...)
        end
    end))
    
    self._cleaner:add(self._networkSignal:connect(function(action, module)
        if action == "setReducers" then
            self._staticStore:_setReducers(module)
        end
    end))

    return self
end



function NetworkStaticStore:get(key)
    return self._staticStore:get(key)
end

function NetworkStaticStore:getChangedSignal(key)
    return self._staticStore:getChangedSignal(key)
end

function NetworkStaticStore:getReducedSignal(key, reducer)
    return self._staticStore:getReducedSignal(key, reducer)
end





function NetworkStaticStore:destroy()
    self._cleaner:destroy()
end

return NetworkStaticStore