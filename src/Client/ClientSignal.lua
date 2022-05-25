local Players = game:GetService("Players")

local Slick = require(script.Parent.Parent.Parent.Slick)
local Cleaner = require(script.Parent.Parent.Parent.Cleaner)

--[=[
    ClientSignal class

    @class ClientSignal
]=]
local ClientSignal = {}
ClientSignal.__index = ClientSignal

function ClientSignal.new(remotes)
    local self = setmetatable({}, ClientSignal)

    self._cleaner = Cleaner.new()

    --[[
        Don't have to worry about caching behavior unique to remotes
        since Slick.Signal can handle or flush queued arguments
    ]]
    self._signal = self._cleaner:add(Slick.Signal.new())
    self._signal:enableQueueing()
    
    self._remote = self._cleaner:add(remotes.remoteEvent)
    
    self._cleaner:add(self._remote.OnClientEvent:Connect(function(...)
        self._signal:fire(...)
    end))

    return self
end

--[=[
    Returns whether or not the passed argument is a ClientSignal or not

    @param obj any
    @return bool
]=]
function ClientSignal.is(obj)
    return typeof(obj) == "table" and getmetatable(obj) == ClientSignal
end

--[=[
    Fires the server with the passed arguments

    @param ... any
]=]
function ClientSignal:fireServer(...)
    self._remote:FireServer(...)
end

--[=[
    Flushes any unprocessed requests
]=]
function ClientSignal:flush()
    self._signal:flush()
end

--[=[
    Connects a handler function to process incoming data

    @param fn function
    @return Connection
]=]
function ClientSignal:connect(fn)
    return self._signal:connect(fn)
end

--[=[
    Returns a promise that resolves when the signal is fired next
]=]
function ClientSignal:promise()
    return self._signal:promise()
end

--[=[
    Prepares ClientSignal instance for garbage collection
]=]
function ClientSignal:destroy()
    self._cleaner:destroy()
    self.destroyed = true
end

return ClientSignal