local Players = game:GetService("Players")

local Promise = require(script.Parent.Parent.Parent.Promise)
local Cleaner = require(script.Parent.Parent.Parent.Cleaner)

local ServerCallback = {}
ServerCallback.__index = ServerCallback

function ServerCallback.new(remoteFunction, middleware)
    local self = setmetatable({}, ServerCallback)

    self._cleaner = Cleaner.new()
    self._remote = self._cleaner:give(remoteFunction)
    
    self._queue = {}

    self._wrappedCallback = function(client, ...)
        return self:callServer(client, ...)
    end

    local boundedCall = function(...)
        if not self._callback then
            warn("ServerCallback has no callback set, so request is being queued")

            table.insert(self._queue, coroutine.running())

            assert(coroutine.yield())
        end

        return self._callback(...)
    end

    if middleware then
        for i = #middleware, 1, -1 do
            local newBoundedCall, cleanup = middleware[i](boundedCall, self)

            boundedCall = newBoundedCall

            if cleanup then
                self._cleaner:give(cleanup)
            end
        end
    end

    self._remote.OnServerInvoke = boundedCall

    return self
end

function ServerCallback:setCallback(callback)
    self._callback = callback

    if callback then
        for _, thread in pairs(self._queue) do
            task.spawn(thread, true)
        end
    end

    table.clear(self._queue)
end

function ServerCallback:flush()
    for _, thread in pairs(self._queue) do
        task.spawn(thread, false, "Request was flushed on the server")
    end

    table.clear(self._queue)
end

function ServerCallback:callClientAsync(client, ...)
    return Promise.try(function(...)
        return self._remote:InvokeClient(...)
    end, client, ...)
end

function ServerCallback:destroy()
    self:flush()
    self._cleaner:destroy()
    self.destroyed = true
end

return ServerCallback