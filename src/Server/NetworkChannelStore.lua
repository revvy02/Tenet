local Players = game:GetService("Players")

local Promise = require(script.Parent.Parent.Parent.Promise)
local Slick = require(script.Parent.Parent.Parent.Slick)
local Cleaner = require(script.Parent.Parent.Parent.Cleaner)

local NetworkSignal = require(script.Parent.NetworkSignal)
local NetworkCallback = require(script.Parent.NetworkCallback)

local NetworkChannelStore = {}
NetworkChannelStore.__index = NetworkChannelStore


function NetworkChannelStore.new(remoteEvent, remoteFunction, processSubscription, )
    local self = setmetatable({}, NetworkChannelStore)

    self._cleaner = Cleaner.new()
    self._networkSignal = self._cleaner:add(NetworkSignal.new(remoteEvent))
    self._networkCallback = self._cleaner:add(NetworkCallback.new(remoteFunction))
    
    self._store = self._cleaner:add(Slick.Store.new())
    self._subscribers = {}

    self._networkCallback:setServerCallback(function(player, action, key)
        if action == "fetch" then
            return self._reducers
        end
    end)

    self._cleaner:add(self._networkSignal:connect(function(player, action, key)
        if action == "subscribe" then
            return self:subscribe(key, player)
        elseif action == "unsubscribe" then
            self:unsubscribe(key, player)
        end
    end))

    self._cleaner:add(self._store.reduced:connect(function(key, reducer, ...)
        self._networkSignal:fireClients(self:getSubscribers(key), "dispatch", key, reducer, ...)
    end))

    self._cleaner:add(Players.PlayerRemoving:Connect(function(player)
        self._subscribers[player] = nil
    end))
end





function NetworkChannelStore:setSubscriptionHandler(fn)
    self._processSubscription = fn
end

function NetworkChannelStore:setUnsubscriptionHandler(fn)
    self._processUnsubscription = fn
end

function NetworkChannelStore:subscribe(key, player)
    local keys = self._subscribers[player]

    if self._processSubscription and self._processSubscription(key, player) then
        if not keys then
            self._subscribers[player] = {[key] = true}
        else
            keys[key] = true
        end
    end
end

function NetworkChannelStore:unsubscribe(key, player)
    local keys = self._subscribers[player]

    if self._processUnsubscription and self._processUnsubscription(key, player) then
        if keys and keys[key] then
            keys[key] = nil

            if not next(keys) then
                self._subscribers[key] = nil
            end
        end
    end
end

function NetworkChannelStore:getSubscribers(key)
    local subscribers = {}

    for player, keys in pairs(self._subscribers) do
        if keys[key] then
            table.insert(subscribers, player)
        end
    end

    return subscribers
end






function NetworkChannelStore:dispatch(key, reducer, ...)
    self._store:dispatch(key, reducer, ...)
end

function NetworkChannelStore:setReducers(module)
    self._reducers = module
    self._networkSignal:fireAllClients("setReducers", module)
end

function NetworkChannelStore:get(key)
    return self._store:get(key)
end

function NetworkChannelStore:getChangedSignal(key)
    return self._store:getChangedSignal(key)
end

function NetworkChannelStore:getReducedSignal(key, reducer)
    return self._store:getReducedSignal(key, reducer)
end







function NetworkChannelStore:destroy()
    self._cleaner:destroy()
end


return NetworkChannelStore