local Cleaner = require(script.Parent.Parent.Parent.Cleaner)
local TrueSignal = require(script.Parent.Parent.Parent.TrueSignal)

local ServerSignal = {}
ServerSignal.__index = ServerSignal

function ServerSignal.new(remoteEvent, inboundMiddleware, outboundMiddleware)
    --[[
        inbound for ratelimiting, rttcing, deserializing
        outbound for serializing, throttling
    ]]
    local self = setmetatable({}, ServerSignal)

    self._cleaner = Cleaner.new()

    --[[
        Don't have to worry about caching behavior unique to remotes
        since Slick.Signal can handle or flush queued arguments
    ]]
    self._signal = self._cleaner:give(TrueSignal.new(false, true))

    --[[
        Can pass a mock remote for testing
    ]]
    self._remote = remoteEvent

    --[[
        wrap fire in middleware (server received)
    ]]
    local fireInbound = function(client, ...)
        self._signal:fire(client, ...)
    end

    local fireOutbound = function(client, ...)
        self._remote:FireClient(client, ...)
    end
    
    if inboundMiddleware then
        for i = #inboundMiddleware, 1, -1 do
            local nextInbound, cleanup = inboundMiddleware[i](fireInbound, self)

            if cleanup then
                self._cleaner:give(cleanup)
            end

            fireInbound = nextInbound
        end
    end

    if outboundMiddleware then
        for i = #outboundMiddleware, 1, -1 do
            local nextOutbound, cleanup = outboundMiddleware[i](fireOutbound, self)

            if cleanup then
                self._cleaner:give(cleanup)
            end

            fireOutbound = nextOutbound
        end
    end

    self.fireClient = fireOutbound
    self._cleaner:give(self._remote.OnServerEvent:Connect(fireInbound))

    return self
end

function ServerSignal:fireClient(client, ...)
    self._remote:FireClient(client, ...)
end

function ServerSignal:fireClients(clients, ...)
    for _, client in pairs(clients) do
        self:fireClient(client, ...)
    end
end

function ServerSignal:flush()
    self._signal:flush()
end

function ServerSignal:connect(fn)
    return self._signal:connect(fn)
end

function ServerSignal:promise()
    return self._signal:promise()
end

function ServerSignal:destroy()
    self._cleaner:destroy()
    self.destroyed = true
end

return ServerSignal