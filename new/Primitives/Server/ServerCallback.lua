local Promise = require(script.Parent.Parent.Parent.Parent.Promise)
local Cleaner = require(script.Parent.Parent.Parent.Parent.Cleaner)
local NetPass = require(script.Parent.Parent.Parent.Parent.NetPass)

local ServerCallback = {}
ServerCallback.__index = ServerCallback

function ServerCallback.new(remoteFunction, options)
    local self = setmetatable({}, ServerCallback)

    self._cleaner = Cleaner.new()
    self._remote = self._cleaner:give(remoteFunction)
    
    self._queue = {}

    local onServerInvoke = function(...)
        if not self._callback then
            warn("ServerCallback has no callback set, so request is being queued")

            table.insert(self._queue, coroutine.running())

            assert(coroutine.yield())
        end

        return self._callback(...)
    end

    if options then
        if options.inbound then
            for i = #options.inbound, 1, -1 do
                local nextOnServerInvoke, cleanup = options.inbound[i](onServerInvoke, self)
                onServerInvoke = nextOnServerInvoke

                if cleanup then
                    self._cleaner:give(cleanup)
                end
            end
        end

        if options.outbound then
            local unboundCallClientAsync = self.callClientAsync

            local callClientAsync = function(client, ...)
                return unboundCallClientAsync(self, client, ...)
            end

            for i = #options.outbound, 1, -1 do
                local nextCallClientAsync, cleanup = options.outbound[i](callClientAsync, self)
                callClientAsync = nextCallClientAsync

                if cleanup then
                    self._cleaner:give(cleanup)
                end
            end

            self.callClientAsync = function(_, client, ...)
                return callClientAsync(client, ...)
            end
        end
    end
    
    self._remote.OnServerInvoke = function(client, ...)
        -- return NetPass.encode(onServerInvoke(client, NetPass.decode(...)))
        return onServerInvoke(client, ...) 
    end

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
        -- return NetPass.decode(self._remote:InvokeClient(client, NetPass.encode(...)))
        return self._remote:InvokeClient(client, ...)
    end, ...)
end

function ServerCallback:destroy()
    self:flush()
    self._cleaner:destroy()
end

return ServerCallback