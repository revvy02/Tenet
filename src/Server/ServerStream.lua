local Cleaner = require(script.Parent.Parent.Parent.Cleaner)
local Promise = require(script.Parent.Parent.Parent.Promise)
local TrueSignal = require(script.Parent.Parent.Parent.TrueSignal)

local ServerSignal = require(script.Parent.ServerSignal)
local StaticStoreServer = require(script.Parent.StaticStoreServer)
local DynamicStoreServer = require(script.Parent.DynamicStoreServer)

local ServerStream = {}
ServerStream.__index = ServerStream

function ServerStream.new(remotes, dynamic, module)
    local self = setmetatable({}, ServerStream)

    self._cleaner = Cleaner.new()
    self._dynamic = dynamic

    self._serverSignal = self._cleaner:give(ServerSignal.new(remotes))

    self.created = self._cleaner:give(TrueSignal.new())
    self.removed = self._cleaner:give(TrueSignal.new())

    return self
end

function ServerStream:create(owner, initial, reducers)
    local store = if self._dynamic then
        self._cleaner:set(owner, DynamicStoreServer._new(self._serverSignal, owner, initial, reducers))
    else
        self._cleaner:set(owner, StaticStoreServer._new(self._serverSignal, owner, initial, reducers))

    self.created:fire(owner, store)

    return store
end

function ServerStream:remove(owner)
    self._cleaner:finalize(owner)
    self.removed:fire(owner)
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