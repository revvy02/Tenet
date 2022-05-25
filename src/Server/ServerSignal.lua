local Players = game:GetService("Players")

local Slick = require(script.Parent.Parent.Parent.Slick)
local Cleaner = require(script.Parent.Parent.Parent.Cleaner)

local NetworkSignal = {}
NetworkSignal.__index = NetworkSignal

function NetworkSignal.new(remote, middleware)
    local self = setmetatable({}, NetworkSignal)

    self._cleaner = Cleaner.new()

    --[[
        Don't have to worry about caching behavior unique to remotes
        since Slick.Signal can handle or flush queued arguments
    ]]
    self._signal = self._cleaner:add(Slick.Signal.new())
    self._signal:enableQueueing()

    --[[
        Can pass a mock remote for testing
    ]]
    self._remote = self._cleaner:add(remote)

    --[[
        wrap fire in middleware (server received)
    ]]
    local boundedFire = function(...)
        self._signal:fire(...)
    end
    
    for i = #middleware, 1, -1 do
        local newBoundedFire, cleanup = middleware[i](boundedFire, self)
        
        if cleanup then
            self._cleaner:add(cleanup)
        end

        boundedFire = newBoundedFire
    end
    
    self.fireServer = function(_, ...)
        boundedFire(...)
    end
    
    self._cleaner:add(self._remote.OnServerEvent:Connect(function(...)
        self:fireServer(...)
    end))

    return self
end

function NetworkSignal:fireClient(client, ...)
    self._remote:FireClient(client, ...)
end

function NetworkSignal:fireClients(clients, ...)
    for _, client in pairs(clients) do
        self._remote:FireClient(client, ...)
    end
end

function NetworkSignal:fireAllClients(...)
    self._remote:FireAllClients(...)
end

function NetworkSignal:fireAllClientsExcept(clients, ...)
    for _, client in pairs(Players:GetPlayers()) do
        if not table.find(clients, client) then
            self._remote:FireClient(client, ...)
        end
    end
end

function NetworkSignal:flushServer()
    self._signal:flush()
end

function NetworkSignal:connect(fn)
    return self._signal:connect(fn)
end

function NetworkSignal:_destroy()
    self._cleaner:destroy()
end

return NetworkSignal