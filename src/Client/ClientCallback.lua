local Players = game:GetService("Players")

local Promise = require(script.Parent.Parent.Parent.Promise)
local Cleaner = require(script.Parent.Parent.Parent.Cleaner)

local ClientCallback = {}
ClientCallback.__index = ClientCallback

--[=[

]=]
function ClientCallback.new(options)
    local self = setmetatable({}, ClientCallback)

    self._remote = options.remoteFunction
    self._signals = {}

    self._wrappedCallback = function(...)
        if self._callback then
            self._callback(...)
        end
    end

    return self
end

function ClientCallback:setClientCallback(callback)
    self._callback = callback
    self._remote.OnClientInvoke = callback and self._wrappedCallback or nil
end

function ClientCallback:flushClient()
    if not self._callback then
        self._remote.OnClientInvoke = self._wrappedCallback
        self._remote.OnClientInvoke = nil
    end
end

function ClientCallback:callServerAsync(...)
    return Promise.try(function(...)
        return self._remote:InvokeServer(...)
    end, ...)
end

function ClientCallback:destroy()
    self.destroyed = true
end

return ClientCallback