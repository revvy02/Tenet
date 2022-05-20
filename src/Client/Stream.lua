local Slick = require(script.Parent.Parent.Parent.Slick)
local Promise = require(script.Parent.Parent.Parent.Promise)
local Cleaner = require(script.Parent.Parent.Parent.Cleaner)

local NetworkSignal = require(script.Parent.NetworkSignal)
local NetworkCallback = require(script.Parent.NetworkCallback)

local Stream = {}
Stream.__index = Stream


function Stream.new(options, Store)
    local self = setmetatable({}, Stream)

    self._cleaner = Cleaner.new()
    
    self._networkSignal = self._cleaner:add(NetworkSignal.new(options.remoteEvent))
    self._networkCallback = self._cleaner:add(NetworkCallback.new(options.remoteFunction))

    self.streamed = self._cleaner:add(Slick.Signal.new())
    self.unstreamed = self._cleaner:add(Slick.Signal.new())

    self._cleaner:add(self._networkSignal:connect(function(action, owner, key, reducer, ...)
        if action == "dispatch" then
            self:get(owner):_dispatch(key, reducer, ...)
        end
    end))

    self._cleaner:add(self._networkSignal:connect(function(action, owner, ...)
        if action == "stream" then
            self._cleaner:set(owner, Store.new(...))
            self.streamed:fire(owner)
         elseif action == "unstream" then
            self._cleaner:finalize(owner)
            self.unstreamed:fire(owner)
        end
    end))

    self._cleaner:add(self._networkSignal:connect(function(action, owner, key, value)
        if action == "load" then
            self:get(owner):_load(key, value)
        elseif action == "unload" then
            self:get(owner):_unload(key)
        end
    end))

    self._cleaner:add(self._networkSignal:connect(function(action, owner, module)
        if action == "setReducers" then
            self:get(owner):_setReducers(module)
        end
    end))

    return self
end

function Stream:get(owner)
    return self._cleaner:get(owner)
end

function Stream:await(owner)
    if self:get(owner) then
        return Promise.resolve(self:get(owner))
    end

    return Promise.fromEvent(self.streamed, function(newOwner)
        return newOwner == owner
    end):andThen(function()
        return self:get(owner)
    end)
end

function Stream:destroy()
    self._cleaner:destroy()
end

return Stream