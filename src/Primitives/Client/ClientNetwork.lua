local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Cleaner = require(script.Parent.Parent.Parent.Parent.Cleaner)
local Slick = require(script.Parent.Parent.Parent.Parent.Slick)
local Promise = require(script.Parent.Parent.Parent.Parent.Promise)

local ClientSignal = require(script.Parent.ClientSignal)
local ClientCallback = require(script.Parent.ClientCallback)
local ClientBroadcast = require(script.Parent.ClientBroadcast)

local holderPromise = Promise.try(function()
    return ReplicatedStorage:WaitForChild("Stellar")
end)

--[=[
    Client class for holding network primitives

    @class ClientNetwork
]=]
local ClientNetwork = {}
ClientNetwork.__index = ClientNetwork

--[=[
    Removes any channels and prepares the ClientNetwork object for garbage collection

    @private
]=]
function ClientNetwork:_destroy()
    self._networkFolderPromise:cancel()

    self._signalsFolderPromise:cancel()
    self._callbacksFolderPromise:cancel()
    self._broadcastsFolderPromise:cancel()

    self._cleaner:destroy()
end

--[=[
    Constructs a new ClientNetwork object

    @param name string
    @return ClientNetwork
]=]
function ClientNetwork.new(name)
    local self = setmetatable({}, ClientNetwork)

    self._cleaner = Cleaner.new()

    self._store = self._cleaner:give(Slick.Store.new({
        clientSignals = {},
        clientCallbacks = {},
        clientBroadcasts = {},
    }))

    self._networkFolderPromise = holderPromise:andThen(function(holder)
        return holder:WaitForChild(name)
    end)

    self._signalsFolderPromise = self._networkFolderPromise:andThen(function(networkFolder)
        return networkFolder:WaitForChild("Signals")
    end)

    self._callbacksFolderPromise = self._networkFolderPromise:andThen(function(networkFolder)
        return networkFolder:WaitForChild("Callbacks")
    end)

    self._broadcastsFolderPromise = self._networkFolderPromise:andThen(function(networkFolder)
        return networkFolder:WaitForChild("Broadcasts")
    end)

    return self
end

--[=[
    Creates a new ClientSignal object

    @param name string
    @param options {inbound: {...function}, outbound: {...function}}
    @return ClientSignal
]=]
function ClientNetwork:createClientSignalAsync(name, options)
    assert(self._store:getValue("clientSignals")[name] == nil, string.format("%s is already an existing ClientSignal", name))

    self._store:dispatch("setIndex", "clientSignals", name, false)

    return self._signalsFolderPromise:andThen(function(signalsFolder)
        return signalsFolder:WaitForChild(name)
    end):andThen(function(remoteEvent)
        local clientSignal = self._cleaner:give(ClientSignal.new(remoteEvent, options), ClientSignal._destroy)

        self._store:dispatch("setIndex", "clientSignals", name, clientSignal)

        return clientSignal
    end)
end

--[=[
    Returns a promise that resolves when the the ClientSignal object with the name is created

    @param name string
    @return Promise
]=]
function ClientNetwork:getClientSignalAsync(name)
    if self._store:getValue("clientSignals")[name] then
        return Promise.resolve(self._store:getValue("clientSignals")[name])
    end

    return Promise.fromEvent(self._store:getReducedSignal("setIndex", "clientSignals"), function(index, value)
        return value and index == name
    end):andThen(function()
        return self._store:getValue("clientSignals")[name]
    end)
end

--[=[
    Creates a new ClientCallback object

    @param name string
    @param options {inbound: {...function}, outbound: {...function}}
    @return ClientCallback
]=]
function ClientNetwork:createClientCallbackAsync(name, options)
    assert(self._store:getValue("clientCallbacks")[name] == nil, string.format("%s is already an existing ClientCallback", name))

    self._store:dispatch("setIndex", "clientCallbacks", name, false)

    return self._callbacksFolderPromise:andThen(function(callbacksFolder)
        return callbacksFolder:WaitForChild(name)
    end):andThen(function(remoteFunction)
        local clientCallback = self._cleaner:give(ClientCallback.new(remoteFunction, options), ClientCallback._destroy)

        self._store:dispatch("setIndex", "clientCallbacks", name, clientCallback)

        return clientCallback
    end)
end

--[=[
    Returns a promise that resolves when the the ClientCallback object with the name is created

    @param name string
    @return Promise
]=]
function ClientNetwork:getClientCallbackAsync(name)
    if self._store:getValue("clientCallbacks")[name] then
        return Promise.resolve(self._store:getValue("clientCallbacks")[name])
    end

    return Promise.fromEvent(self._store:getReducedSignal("setIndex", "clientCallbacks"), function(index, value)
        return value and index == name
    end):andThen(function()
        return self._store:getValue("clientCallbacks")[name]
    end)
end

--[=[
    Creates a new ClientBroadcast object

    @param name string
    @return ClientBroadcast
]=]
function ClientNetwork:createClientBroadcastAsync(name)
    assert(self._store:getValue("clientBroadcasts")[name] == nil, string.format("%s is already an existing ClientBroadcast", name))

    self._store:dispatch("setIndex", "clientBroadcasts", name, false)

    return self._broadcastsFolderPromise:andThen(function(broadcastsFolder)
        return broadcastsFolder:WaitForChild(name)
    end):andThen(function(broadcastFolder)
        local clientBroadcast = self._cleaner:give(ClientBroadcast.new(broadcastFolder:WaitForChild("RemoteEvent"), broadcastFolder:WaitForChild("RemoteFunction")), ClientBroadcast._destroy)

        self._store:dispatch("setIndex", "clientBroadcasts", name, clientBroadcast)

        return clientBroadcast
    end)
end

--[=[
    Returns a promise that resolves when the the ClientBroadcast object with the name is created

    @param name string
    @return Promise
]=]
function ClientNetwork:getClientBroadcastAsync(name)
    if self._store:getValue("clientBroadcasts")[name] then
        return Promise.resolve(self._store:getValue("clientBroadcasts")[name])
    end

    return Promise.fromEvent(self._store:getReducedSignal("setIndex", "clientBroadcasts"), function(index, value)
        return value and index == name
    end):andThen(function()
        return self._store:getValue("clientBroadcasts")[name]
    end)
end

return ClientNetwork