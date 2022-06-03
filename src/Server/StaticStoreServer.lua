local Slick = require(script.Parent.Parent.Parent.Slick)
local Cleaner = require(script.Parent.Parent.Parent.Cleaner)
local Promise = require(script.Parent.Parent.Parent.Promise)

local StaticStoreServer = {}
StaticStoreServer.__index = StaticStoreServer

function StaticStoreServer._new(serverSignal, owner, initial, reducers)
    local self = setmetatable({}, StaticStoreServer)

    self._owner = owner
    self._viewers = {}
    self._serverSignal = serverSignal

    self._cleaner = Cleaner.new()

    self._store = self._cleaner:give(Slick.Store.new(initial, reducers))

    self.reduced = self._store.reduced
    self.changed = self._store.changed

    self._cleaner:give(self._store.reduced:connect(function(key, reducer, ...)
        self._serverSignal:fireClients(self:getViewers(), "dispatch", self._owner, key, reducer, ...)
    end))

    self._cleaner:give(function()
        self._serverSignal:fireClients(self:getViewers(), "unstream", self._owner)
    end)

    return self
end



function StaticStoreServer:getViewers()
    return self._viewers
end

function StaticStoreServer:isViewing(player)
    return table.find(self._viewers, player) ~= nil
end




function StaticStoreServer:stream(player)
    if self:watching(player) then
        return
    end

    table.insert(self._viewers, player)

    self._serverSignal:fireClient(player, "stream", self._owner, self._store:getState(), self._reducersModule)
end

function StaticStoreServer:unstream(player)
    if not self:watching(player) then
        return
    end

    table.remove(self._viewers, table.find(self._viewers, player))

    self._serverSignal:fireClient(player, "unstream", self._owner)
end




function StaticStoreServer:dispatch(key, reducer, ...)
    self._store:dispatch(key, reducer, ...)
end

function StaticStoreServer:getValue(key)
    return self._store:getValue(key)
end

function StaticStoreServer:getChangedSignal(key)
    return self._store:getChangedSignal(key)
end

function StaticStoreServer:getReducedSignal(key)
    return self._store:getReducedSignal(key)
end




function StaticStoreServer:destroy()
    self._cleaner:destroy()
end

return StaticStoreServer