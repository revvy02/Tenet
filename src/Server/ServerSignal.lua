local Cleaner = require(script.Parent.Parent.Parent.Cleaner)
local NetPass = require(script.Parent.Parent.Parent.NetPass)
local TrueSignal = require(script.Parent.Parent.Parent.TrueSignal)

local ServerSignal = {}
ServerSignal.__index = ServerSignal

function ServerSignal.new(remoteEvent, options)
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

    local unboundFireClient = self.fireClient

    local fireClient = function(client, ...)
        unboundFireClient(self, client, ...)
    end

    local onServerEvent = function(client, ...)
        self._signal:fire(client, NetPass.decode(...))
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

    self._cleaner:give(self._remote.OnServerEvent:Connect(onServerEvent))
    
    return self
end

function ServerSignal:fireClient(client, ...)
    self._remote:FireClient(client, NetPass.encode(...))
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