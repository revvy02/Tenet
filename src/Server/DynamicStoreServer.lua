local Players = game:GetService("Players")

local Slick = require(script.Parent.Parent.Parent.Slick)
local Cleaner = require(script.Parent.Parent.Parent.Cleaner)
local Promise = require(script.Parent.Parent.Parent.Promise)
local TrueSignal = require(script.Parent.Parent.Parent.TrueSignal)

local DynamicStoreServer = {}
DynamicStoreServer.__index = DynamicStoreServer

function DynamicStoreServer._new(serverSignal, owner, initial, reducers)
    local self = setmetatable({}, DynamicStoreServer)

    self._viewers = {}
    self._subscribers = {}

    self._owner = owner
    self._serverSignal = serverSignal

    self._cleaner = Cleaner.new()

    self._store = self._cleaner:give(Slick.Store.new(initial, reducers))

    self.reduced = self._store.reduced
    self.changed = self._store.changed

    self._cleaner:give(self._store.reduced:connect(function(key, reducer, ...)
        self._serverSignal:fireClients(self:getSubscribers(key), "dispatch", self._owner, key, reducer, ...)
    end))

    self._cleaner:give(function()
        self._serverSignal:fireClients(self:getViewers(), "unstream", self._owner)
    end)

    self._cleaner:give(Players.PlayerRemoving:Connect(function(player)
        self:unstream(player)
    end))

    return self
end



function DynamicStoreServer:getSubscribers(key)
    return self._subscribers[key]
end

function DynamicStoreServer:getViewingSubscribers(key)
    
end

function DynamicStoreServer:getViewers()
    return self._viewers
end








function DynamicStoreServer:isSubscribed(key, player)
    local list = self._subscribers[key]

    return list ~= nil and table.find(list, player) ~= nil
end

function DynamicStoreServer:isViewing(player)
    return table.find(self._viewers, player) ~= nil
end










function DynamicStoreServer:subscribe(key, player)
    if not self:isViewing(player) then
        self:stream(player)
    end
    
    if self:isSubscribed(key, player) then
        return
    end

    local list = self._subscribers[key]

    if not list then
        list = {}
        self._subscribers[key] = list
    end

    table.insert(list, player)

    self._serverSignal:fireClient(player, "load", self._owner, key, self:getValue(key))
end

function DynamicStoreServer:unsubscribe(key, player)
    if not self:isSubscribed(key, player) then
        return
    end

    local list = self._subscribers[key]

    table.remove(list, table.find(list, player))

    self._serverSignal:fireClient(player, "unload", self._owner, key)
end










function DynamicStoreServer:stream(player)
    if self:isViewing(player) then
        return
    end

    table.insert(self._viewers, player)

    self._serverSignal:fireClient(player, "dynamic", self._owner, self._reducersModule)
end

function DynamicStoreServer:unstream(player)
    if not self:isViewing(player) then
        return
    end

    table.remove(self._viewers, table.find(self._viewers, player))

    for key in pairs(self._subscribers) do
        self:unsubscribe(key, player)
    end

    self._serverSignal:fireClient(player, "unstream", self._owner)
end






function DynamicStoreServer:dispatch(key, reducer, ...)
    self._store:dispatch(key, reducer, ...)
end

function DynamicStoreServer:getValue(key)
    return self._store:getValue(key)
end

function DynamicStoreServer:getChangedSignal(key)
    return self._store:getChangedSignal(key)
end

function DynamicStoreServer:getReducedSignal(key)
    return self._store:getReducedSignal(key)
end




function DynamicStoreServer:destroy()
    self._cleaner:destroy()
end

return DynamicStoreServer