local Cleaner = require(script.Parent.Parent.Parent.Parent.Cleaner)
local NetPass = require(script.Parent.Parent.Parent.Parent.NetPass)
local TrueSignal = require(script.Parent.Parent.Parent.Parent.TrueSignal)

--[=[
    ClientSignal class

    @class ClientSignal
]=]
local ClientSignal = {}
ClientSignal.__index = ClientSignal

--[=[
    Constructs a new ClientSignal object

    @param remoteEvent RemoteEvent
    @param options Options
    @return ClientSignal
]=]
function ClientSignal.new(remoteEvent, options)
    local self = setmetatable({}, ClientSignal)

    self._cleaner = Cleaner.new()

    --[[
        Don't have to worry about caching behavior unique to remotes
        since Slick.Signal can handle or flush queued arguments
    ]]
    self._signal = self._cleaner:give(TrueSignal.new(false, true))
    
    self._remote = remoteEvent

    local unboundFireServer = self.fireServer

    local fireServer = function(...)
        unboundFireServer(self, ...)
    end

    local onClientEvent = function(...)
        self._signal:fire(...)
    end
    
    if options then
        if options.inbound then
            for i = #options.inbound, 1, -1 do
                local nextOnClientEvent, cleanup = options.inbound[i](onClientEvent, self)
                onClientEvent = nextOnClientEvent

                if cleanup then
                    self._cleaner:give(cleanup)
                end
            end
        end

        if options.outbound then
            for i = #options.outbound, 1, -1 do
                local nextFireServer, cleanup = options.outbound[i](fireServer, self)
                fireServer = nextFireServer

                if cleanup then
                    self._cleaner:give(cleanup)
                end
            end

            self.fireServer = function(_, ...)
                fireServer(...)
            end
        end
    end

    self._cleaner:give(self._remote.OnClientEvent:Connect(function(...)
        -- onClientEvent(NetPass.decode(...))
       onClientEvent(...)
    end))

    return self
end

--[=[
    Fires the server with the passed arguments

    @param ... any
]=]
function ClientSignal:fireServer(...)
    -- self._remote:FireServer(NetPass.encode(...))
    self._remote:FireServer(...)
end

--[=[
    Flushes any pending requests
]=]
function ClientSignal:flush()
    self._signal:flush()
end

--[=[
    Connects a handler function to process incoming requests
    
    @param fn (...any) -> (...any)
    @return Connection
]=]
function ClientSignal:connect(fn)
    return self._signal:connect(fn)
end

--[=[
    Returns a promise that resolves when the signal is fired
]=]
function ClientSignal:promise()
    return self._signal:promise()
end

--[=[
    Flushes any pending requests and prepares the ClientSignal object for garbage collection
]=]
function ClientSignal:destroy()
    self:flush()
    self._cleaner:destroy()
end

return ClientSignal