local Players = game:GetService("Players")

local Promise = require(script.Parent.Parent.Parent.Promise)
local Cleaner = require(script.Parent.Parent.Parent.Cleaner)

local ServerCallback = {}
ServerCallback.__index = ServerCallback

function ServerCallback.new(remotes, middleware)
    local self = setmetatable({}, ServerCallback)

    self._cleaner = Cleaner.new()
    self._remote = self._cleaner:add(remotes.remoteFunction)

    self._wrappedCallback = function(client, ...)
        return self:callServer(client, ...)
    end

    --[[
        Middleware nesting
    ]]
    local boundedCall = function(...)
        return self:callServer(...)
    end

    for i = #middleware, 1, -1 do
        local newBoundedCall, cleanup = middleware[i](boundedCall, self)

        boundedCall = newBoundedCall

        self._cleaner:add(cleanup)
    end

    self.callServer = function(_, ...)
        return boundedCall(...)
    end

    self._remote.OnServerInvoke = function(...)
        if not self._callback then
            table.insert(self._queue, {
                args = {...},
                thread = coroutine.running(),
            })

            return coroutine.yield()
        end

        return self._callback(...)
    end

    return self
end

function ServerCallback:setCallback(callback)
    self._callback = callback
    self._remote.OnServerInvoke = callback and self._wrappedCallback or nil
end

function ServerCallback:flush()
    if not self._callback then
        self._remote.OnServerInvoke = self._wrappedCallback
        self._remote.OnServerInvoke = nil
    end
end

--[=[

]=]
function ServerCallback:callServer(client, ...)
    if self._callback then
        return self._callback(client, ...)
    end
end

function ServerCallback:callClientAsync(client, ...)
    return Promise.try(function(...)
        return self._remote:InvokeClient(...)
    end, client, ...)
end

function ServerCallback:destroy()
    self._cleaner:destroy()
end

return ServerCallback