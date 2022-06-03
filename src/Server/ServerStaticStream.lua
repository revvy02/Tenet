local Slick = require(script.Parent.Parent.Parent.Slick)
local Cleaner = require(script.Parent.Parent.Parent.Cleaner)
local Promise = require(script.Parent.Parent.Parent.Promise)

local ServerSignal = require(script.Parent.ServerSignal)
local StaticStore = require(script.Parent.StaticStore)

local ServerStaticStream = {}
ServerStaticStream.__index = ServerStaticStream

function ServerStaticStream.new(remotes, middleware)
    local self = setmetatable({}, ServerStaticStream)

    self._cleaner = Cleaner.new()

    self._serverSignal = self._cleaner:give(ServerSignal.new(remotes, middleware))

    self.created = self._cleaner:give(Slick.Signal.new())
    self.removed = self._cleaner:give(Slick.Signal.new())

    return self
end



function ServerStaticStream:create(owner, initial, reducers)
    local store = self._cleaner:set(owner, StaticStore.new(self._serverSignal, owner, initial, reducers))

    self.created:fire(owner, store)

    return store
end

function ServerStaticStream:remove(owner)
    self._cleaner:finalize(owner)
    self.removed:fire(owner)
end

function ServerStaticStream:get(owner)
    return self._cleaner:get(owner)
end

function ServerStaticStream:createdAsync(owner)
    if self._cleaner:get(owner) then
        return Promise.resolve()
    end

    return Promise.fromEvent(self.created, function(newOwner)
        return newOwner == owner
    end)
end



function ServerStaticStream:destroy()
    self._cleaner:destroy()
end

return ServerStaticStream