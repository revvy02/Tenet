local Cleaner = require(script.Parent.Parent.Parent.Cleaner)
local Promise = require(script.Parent.Parent.Parent.Promise)
local TrueSignal = require(script.Parent.Parent.Parent.TrueSignal)

local ServerSignal = require(script.Parent.ServerSignal)
local StaticStoreServer = require(script.Parent.StaticStoreServer)
local DynamicStoreServer = require(script.Parent.DynamicStoreServer)

local ServerStream = {}
ServerStream.__index = ServerStream

function ServerStream.new(remoteEvent, dynamic, module)
    local self = setmetatable({}, ServerStream)

    self._dynamic = dynamic
    self._module = module

    self._cleaner = Cleaner.new()

    self._serverSignal = self._cleaner:give(ServerSignal.new(remoteEvent))

    self.created = self._cleaner:give(TrueSignal.new())
    self.removed = self._cleaner:give(TrueSignal.new())

    return self
end

function ServerStream:create(owner, initial)
    if self._dynamic then
        return DynamicStoreServer._new(self, owner, initial)
    else
        return StaticStoreServer._new(self, owner, initial)
    end
end

function ServerStream:remove(owner)
    self._cleaner:finalize(owner)
end

function ServerStream:get(owner)
    return self._cleaner:get(owner)
end

function ServerStream:createdAsync(owner)
    if self._cleaner:get(owner) then
        return Promise.resolve()
    end

    return Promise.fromEvent(self.created, function(newOwner)
        return newOwner == owner
    end)
end

function ServerStream:destroy()
    self._cleaner:destroy()
    self.destroyed = true
end

return ServerStream