local Players = game:GetService("Players")

local Promise = require(script.Parent.Parent.Parent.Promise)
local Cleaner = require(script.Parent.Parent.Parent.Cleaner)

local NetworkCallback = {}
NetworkCallback.__index = NetworkCallback

function NetworkCallback.new(remote, middleware)
    local self = setmetatable({}, NetworkCallback)

    self._cleaner = Cleaner.new()
    self._remote = self._cleaner:add(remote)

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

    return self
end

function NetworkCallback:setServerCallback(callback)
    self._callback = callback
    self._remote.OnServerInvoke = callback and self._wrappedCallback or nil
end

function NetworkCallback:flush()
    if not self._callback then
        self._remote.OnServerInvoke = self._wrappedCallback
        self._remote.OnServerInvoke = nil
    end
end

--[=[

]=]
function NetworkCallback:callServer(client, ...)
    if self._callback then
        return self._callback(client, ...)
    end
end

function NetworkCallback:callClient(client, ...)
    return Promise.try(function(...)
        return self._remote:InvokeClient(...)
    end, client, ...)
end

function NetworkCallback:destroy()
    self._cleaner:destroy()
end

return NetworkCallback