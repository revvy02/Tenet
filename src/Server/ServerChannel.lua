local Cleaner = require(script.Parent.Parent.Parent.Cleaner)
local Promise = require(script.Parent.Parent.Parent.Promise)
local TrueSignal = require(script.Parent.Parent.Parent.TrueSignal)

local ServerSignal = require(script.Parent.ServerSignal)
local ServerCallback = require(script.Parent.ServerCallback)
local StaticStoreServer = require(script.Parent.StaticStoreServer)
local DynamicStoreServer = require(script.Parent.DynamicStoreServer)

local ServerChannel = {}
ServerChannel.__index = ServerChannel

function ServerChannel.new(remoteEvent, remoteFunction, dynamic, module)
    local self = setmetatable({}, ServerChannel)

    self._dynamic = dynamic
    self._module = module

    self._cleaner = Cleaner.new()

    self._serverSignal = self._cleaner:give(ServerSignal.new(remoteEvent))
    self._serverCallback = self._cleaner:give(ServerCallback.new(remoteFunction))

    self._serverCallback:setCallback(function()
        return module
    end)

    self.created = self._cleaner:give(TrueSignal.new())
    self.removed = self._cleaner:give(TrueSignal.new())

    return self
end

function ServerChannel:create(owner, initial)
    if self._dynamic then
        return DynamicStoreServer._new(self, owner, initial)
    else
        return StaticStoreServer._new(self, owner, initial)
    end
end

function ServerChannel:remove(owner)
    self._cleaner:finalize(owner)
end

function ServerChannel:get(owner)
    return self._cleaner:get(owner)
end

function ServerChannel:destroy()
    self._cleaner:destroy()
    self.destroyed = true
end

return ServerChannel