local Cleaner = require(script.Parent.Parent.Parent.Parent.Cleaner)
local NetPass = require(script.Parent.Parent.Parent.Parent.NetPass)
local TrueSignal = require(script.Parent.Parent.Parent.Parent.TrueSignal)

--[=[
    Stellar equivalent for RemoteEvent

    @class ServerSignaL
]=]
local ServerSignal = {}
ServerSignal.__index = ServerSignal

--[=[
    Constructs a new ServerSignal object

    @param remoteEvent RemoteEvent
    @param options Options
    @return ServerSignal
]=]
function ServerSignal.new(remoteEvent, options)
    local self = setmetatable({}, ServerSignal)

    self._cleaner = Cleaner.new()
    self._signal = self._cleaner:give(TrueSignal.new(false, true))

    self._remote = remoteEvent

    local unboundFireClient = self.fireClient

    local fireClient = function(...)
        unboundFireClient(self, ...)
    end

    local onServerEvent = function(...)
        self._signal:fire(...)
    end
    
    if options then
        if options.inboundMiddleware then
            for i = #options.inboundMiddleware, 1, -1 do
                local nextOnServerEvent, cleanup = options.inboundMiddleware[i](onServerEvent, self)
                onServerEvent = nextOnServerEvent

                if cleanup then
                    self._cleaner:give(cleanup)
                end
            end
        end

        if options.outboundMiddleware then
            for i = #options.outboundMiddleware, 1, -1 do
                local nextFireClient, cleanup = options.outboundMiddleware[i](fireClient, self)
                fireClient = nextFireClient

                if cleanup then
                    self._cleaner:give(cleanup)
                end
            end

            self.fireClient = function(_, client, ...)
                fireClient(client, ...)
            end
        end
    end

    self._cleaner:give(self._remote.OnServerEvent:Connect(function(client, ...)
        -- onServerEvent(client, NetPass.decode(...))
        onServerEvent(client, ...)
    end))
    
    return self
end

--[=[
    Fires the client with the passed args

    @param client Player
]=]
function ServerSignal:fireClient(client, ...)
    -- self._remote:FireClient(client, NetPass.encode(...))
    self._remote:FireClient(client, ...)
end

--[=[
    Fires the each client in the passed client list with the passed args

    @param clients {...Player}
]=]
function ServerSignal:fireClients(clients, ...)
    for _, client in pairs(clients) do
        self:fireClient(client, ...)
    end
end

--[=[
    Flushes any pending requests
]=]
function ServerSignal:flush()
    self._signal:flush()
end

--[=[
    Connects a handler function to the ServerSignal object to process any incoming requests

    @param fn (Player, ...any) -> (...any)
    @return Connection
]=]
function ServerSignal:connect(fn)
    return self._signal:connect(fn)
end

--[=[
    Returns a promise that resolves when the ServerSignal object is fired
]=]
function ServerSignal:promise()
    return self._signal:promise()
end

--[=[
    Flushes any pending requests and prepares the ServerSignal object for garbage collection
]=]
function ServerSignal:destroy()
    self:flush()
    self._cleaner:destroy()
end

return ServerSignal