local Players = game:GetService("Players")

local Slick = require(script.Parent.Parent.Parent.Slick)
local Cleaner = require(script.Parent.Parent.Parent.Cleaner)
local TrueSignal = require(script.Parent.Parent.Parent.TrueSignal)

local ServerSignal = {}
ServerSignal.__index = ServerSignal

function ServerSignal.new(remotes, middleware)
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
    self._remote = remotes.remoteEvent

    --[[
        wrap fire in middleware (server received)
    ]]
    local boundedFire = function(...)
        self._signal:fire(...)
    end
    
    if middleware then
        for i = #middleware, 1, -1 do
            local newBoundedFire, cleanup = middleware[i](boundedFire, self)
            
            if cleanup then
                self._cleaner:give(cleanup)
            end

            boundedFire = newBoundedFire
        end
    end
    
    self._cleaner:give(self._remote.OnServerEvent:Connect(boundedFire))

    return self
end

function ServerSignal:fireClient(client, ...)
    self._remote:FireClient(client, ...)
end

function ServerSignal:fireClients(clients, ...)
    for _, client in pairs(clients) do
        self._remote:FireClient(client, ...)
    end
end

function ServerSignal:fireAllClients(...)
    self._remote:FireAllClients(...)
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