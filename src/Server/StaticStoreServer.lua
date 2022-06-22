local Players = game:GetService("Players")

local Slick = require(script.Parent.Parent.Parent.Slick)
local Cleaner = require(script.Parent.Parent.Parent.Cleaner)
local Promise = require(script.Parent.Parent.Parent.Promise)
local TrueSignal = require(script.Parent.Parent.Parent.TrueSignal)

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

    self._cleaner:give(Players.PlayerRemoving:Connect(function(player)
        for key in pairs(self._subscribers) do
            self:unsubscribe(key, player)
        end
    end))

    return self
end



function StaticStoreServer:getViewers()
    return self._viewers
end

function StaticStoreServer:isViewing(player)
    return table.find(self._viewers, player) ~= nil
end




function StaticStoreServer:stream(player)
    if self:isViewing(player) then
        return
    end

    table.insert(self._viewers, player)

    self._serverSignal:fireClient(player, "static", self._owner, self._store:getState(), self._reducersModule)
end

function StaticStoreServer:unstream(player)
    if not self:isViewing(player) then
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

function StaticStoreServer:getReducedSignal(key, reducer)
    return self._store:getReducedSignal(key, reducer)
end




function StaticStoreServer:destroy()
    self._cleaner:destroy()
    self.destroyed = true
end

return StaticStoreServer