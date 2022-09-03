local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Promise = require(script.Parent.Parent.Parent.Parent.Promise)
local Cleaner = require(script.Parent.Parent.Parent.Parent.Cleaner)
local TrueSignal = require(script.Parent.Parent.Parent.Parent.TrueSignal)
local Slick = require(script.Parent.Parent.Parent.Parent.Slick)

local ServerSignal = require(script.Parent.ServerSignal)
local ServerCallback = require(script.Parent.ServerCallback)
local ServerBroadcast = require(script.Parent.ServerBroadcast)

local ServerNetwork = {}

function ServerNetwork.new(name)
    local self = setmetatable({}, ServerNetwork)

    self._cleaner = Cleaner.new()

    self._networkFolder = self._cleaner:give(Instance.new("Folder"))
    self._networkFolder.Name = name

    self._serverSignalFolder = self._cleaner:give(Instance.new("Folder"))
    self._serverCallbackFolder = self._cleaner:give(Instance.new("Folder"))
    self._serverBroadcastFolder = self._cleaner:give(Instance.new("Folder"))

    self._serverSignalFolder.Parent = self._networkFolder
    self._serverCallbackFolder.Parent = self._networkFolder
    self._serverBroadcastFolder.Parent = self._networkFolder

    self._store = self._cleaner:give(Slick.Store.new({
        serverSignals = {},
        serverCallbacks = {},
        serverBroadcasts = {},
    }))

    self.logged = self._cleaner:give(TrueSignal.new())

    self._log = function(...)
        self.logged:fire(...)
    end

    self._networkFolder.Parent = ReplicatedStorage

    return self
end

function ServerNetwork:createServerSignal(name, options)
    assert(not self._store:getValue("serverSignals")[name], string.format("%s is already an existing ServerSignal", name))

    local remoteEvent = Instance.new("RemoteEvent")
    remoteEvent.Parent = self._serverSignalFolder

    self._store:dispatch("serverSignals", "setIndex", name, ServerSignal.new(remoteEvent, {
        log = options.log or self._log,
        inbound = options.inbound,
        outbound = options.outbound,
    }))

    return self._store:getValue("serverSignals")[name]
end

function ServerNetwork:getServerSignalAsync(name)
    if self:_get("serverSignals", name) then
        return Promise.resolve(self._store:getValue("serverSignals")[name])
    end

    return Promise.fromEvent(self._store:getReducedSignal("serverSignals", "setIndex"), function(index, value)
        return index == name
    end):andThen(function()
        return self._store:getValue("serverSignals")[name]
    end)
end



function ServerNetwork:createServerCallback(name, options)
    assert(not self._store:getValue("serverCallbacks")[name], string.format("%s is already an existing ServerCallback", name))

    local remoteFunction = Instance.new("RemoteFunction")
    remoteFunction.Name = name
    remoteFunction.Parent = self._serverCallbacksFolder

    self._store:dispatch("serverCallbacks", "setIndex", name, ServerCallback.new(remoteFunction, {
        log = options.log or self._log,
        inbound = options.inbound,
        outbound = options.outbound,
    }))

    return self._store:getValue("serverCallbacks")[name]
end

function ServerNetwork:getServerCallbackAsync(name)
    if self:_get("serverCallbacks", name) then
        return Promise.resolve(self._store:getValue("serverCallbacks")[name])
    end

    return Promise.fromEvent(self._store:getReducedSignal("serverCallbacks", "setIndex"), function(index)
        return index == name
    end):andThen(function()
        return self._store:getValue("serverCallbacks")[name]
    end)
end

function ServerNetwork:createServerBroadcast(name, options)
    assert(not self._store:getValue("serverBroadcasts")[name], string.format("%s is already an existing ServerBroadcast", name))

    local folder = Instance.new("Folder")
    local remoteEvent = Instance.new("RemoteEvent")
    local remoteFunction = Instance.new("RemoteFunction")
    
    folder.Name = name
    remoteEvent.Parent = folder
    remoteFunction.Parent = folder
    folder.Parent = self._serverBroadcastFolder

    self._store:dispatch("serverBroadcasts", "setIndex", name, ServerBroadcast.new(remoteEvent, remoteFunction, {
        log = options.log or self._log,
        module = options.module,
    }))

    return self._store:getValue("serverBroadcasts")[name]
end

function ServerNetwork:getServerBroadcastAsync(name)
    if self:_get("serverBroadcasts", name) then
        return Promise.resolve(self._store:getValue("serverBroadcasts")[name])
    end
    
    return Promise.fromEvent(self._store:getReducedSignal("serverBroadcasts", "setIndex"), function(index)
        return index == name
    end):andThen(function()
        return self._store:getValue("serverBroadcasts")[name]
    end)
end

function ServerNetwork:destroy()
    self._cleaner:destroy()
end

return ServerNetwork