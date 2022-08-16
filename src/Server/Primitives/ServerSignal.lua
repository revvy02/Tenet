local Cleaner = require(script.Parent.Parent.Parent.Parent.Cleaner)
local NetPass = require(script.Parent.Parent.Parent.Parent.NetPass)
local TrueSignal = require(script.Parent.Parent.Parent.Parent.TrueSignal)

local ServerSignal = {}
ServerSignal.__index = ServerSignal

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
        if options.inbound then
            for i = #options.inbound, 1, -1 do
                local nextOnServerEvent, cleanup = options.inbound[i](onServerEvent, self)
                onServerEvent = nextOnServerEvent

                if cleanup then
                    self._cleaner:give(cleanup)
                end
            end
        end

        if options.outbound then
            for i = #options.outbound, 1, -1 do
                local nextFireClient, cleanup = options.outbound[i](fireClient, self)
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

function ServerSignal:fireClient(client, ...)
    -- self._remote:FireClient(client, NetPass.encode(...))
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
end

return ServerSignal