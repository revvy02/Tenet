local ServerDynamicStream = {}
ServerDynamicStream.__index = ServerDynamicStream

function ServerDynamicStream.new(remotes, middleware)
    local self = setmetatable({}, ServerDynamicStream)

    self._cleaner = Cleaner.new()

    self._serverSignal = self._cleaner:give(ServerSignal.new(remotes, middleware))

    self.created = self._cleaner:give(Slick.Signal.new())
    self.removed = self._cleaner:give(Slick.Signal.new())

    return self
end



function ServerDynamicStream:create(owner, initial, reducers)
    local store = self._cleaner:set(owner, DynamicStore.new(self._serverSignal, owner, initial, reducers))

    self.created:fire(owner, store)

    return store
end

function ServerDynamicStream:remove(owner)
    self._cleaner:finalize(owner)
    self.removed:fire(owner)
end

function ServerDynamicStream:get(owner)
    return self._cleaner:get(owner)
end

function ServerDynamicStream:createdAsync(owner)
    if self._cleaner:get(owner) then
        return Promise.resolve()
    end

    return Promise.fromEvent(self.created, function(newOwner)
        return newOwner == owner
    end)
end



function ServerDynamicStream:destroy()
    self._cleaner:destroy()
end

return ServerDynamicStream