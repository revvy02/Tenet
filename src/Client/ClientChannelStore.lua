local Promise = require(script.Parent.Parent.Parent.Promise)
local Slick = require(script.Parent.Parent.Parent.Slick)
local Cleaner = require(script.Parent.Parent.Parent.Cleaner)

local ClientSignal = require(script.Parent.ClientSignal)
local ClientCallback = require(script.Parent.ClientCallback)
local ChannelStore = require(script.Parent.ChannelStore)

local ClientChannelStore = {}
ClientChannelStore.__index = ClientChannelStore

function ClientChannelStore.new(options)
    local self = setmetatable({}, ClientChannelStore)

    self._cleaner = Cleaner.new()
    self._networkSignal = self._cleaner:add(ClientSignal.new(options.remoteEvent))
    self._networkCallback = self._cleaner:add(ClientCallback.new(options.remoteFunction))

    self._channelStore = self._cleaner:add(ChannelStore.new(self._networkCallback:callServer("fetch"):await()))

    self.changed = self._channelStore.changed
    self.reduced = self._channelStore.reduced

    self._cleaner:add(self._networkSignal:connect(function(action, key, value)
        if action == "load" then
            self._channelStore:_load(key, value)
        elseif action == "unload" then
            self._channelStore:_unload(key, value)
        end
    end))

    self._cleaner:add(self._networkSignal:connect(function(action, key, reducer, ...)
        if action == "dispatch" then
            self._channelStore:_dispatch(key, reducer, ...)
        end
    end))
    
    self._cleaner:add(self._networkSignal:connect(function(action, module)
        if action == "setReducers" then
            self._channelStore:_setReducers(module)
        end
    end))

    return self
end




function ClientChannelStore:subscribeAsync(key)
    return self._networkCallback:callServerAsync("subscribe", key)
end

function ClientChannelStore:unsubscribeAsync(key)
    return self._networkCallback:callServerAsync("unsubscribe", key)
end

function ClientChannelStore:loadedAsync(key)
    return self._channelStore:loadedAsync(key)
end




function ClientChannelStore:get(key)
    return self._channelStore:get(key)
end

function ClientChannelStore:getChangedSignal(key)
    return self._channelStore:getChangedSignal(key)
end

function ClientChannelStore:getReducedSignal(key, reducer)
    return self._channelStore:getReducedSignal(key, reducer)
end




function ClientChannelStore:destroy()
    self._cleaner:destroy()
end



return ClientChannelStore