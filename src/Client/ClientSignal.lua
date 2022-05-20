local Players = game:GetService("Players")

local Slick = require(script.Parent.Parent.Parent.Slick)
local Cleaner = require(script.Parent.Parent.Parent.Cleaner)

local ClientSignal = {}
ClientSignal.__index = ClientSignal

function ClientSignal.new(options)
    local self = setmetatable({}, ClientSignal)

    self._cleaner = Cleaner.new()

    --[[
        Don't have to worry about caching behavior unique to remotes
        since Slick.Signal can handle or flush queued arguments
    ]]
    self._signal = self._cleaner:add(Slick.Signal.new())
    self._signal:enableQueueing()
    
    self._remote = self._cleaner:add(options.remoteEvent)
    
    self._cleaner:add(self._remote.OnServerEvent:Connect(function(...)
        self._signal:fire(...)
    end))

    return self
end

function ClientSignal:fireServer(client, ...)
    self._remote:FireServer(client, ...)
end

function ClientSignal:flushClient()
    self._signal:flush()
end

function ClientSignal:connect(fn)
    return self._signal:connect(fn)
end

function ClientSignal:destroy()
    self._cleaner:destroy()
end

return ClientSignal