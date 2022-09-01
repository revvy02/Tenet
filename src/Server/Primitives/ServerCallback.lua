local Promise = require(script.Parent.Parent.Parent.Parent.Promise)
local Cleaner = require(script.Parent.Parent.Parent.Parent.Cleaner)
local NetPass = require(script.Parent.Parent.Parent.Parent.NetPass)

--[=[
    Stellar equivalent for RemoteFunction

    @class ServerCallback
]=]
local ServerCallback = {}
ServerCallback.__index = ServerCallback

--[=[
    Constructs a new ServerCallback object

    @param remoteFunction RemoteFunction
    @param options Options
    @return ServerCallback
]=]
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
        if options.inboundMiddleware then
            for i = #options.inboundMiddleware, 1, -1 do
                local nextOnServerInvoke, cleanup = options.inboundMiddleware[i](onServerInvoke, self)
                onServerInvoke = nextOnServerInvoke

                if cleanup then
                    self._cleaner:give(cleanup)
                end
            end
        end

        if options.outboundMiddleware then
            local unboundCallClientAsync = self.callClientAsync

            local callClientAsync = function(client, ...)
                return unboundCallClientAsync(self, client, ...)
            end

            for i = #options.outboundMiddleware, 1, -1 do
                local nextCallClientAsync, cleanup = options.outboundMiddleware[i](callClientAsync, self)
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

--[=[
    Sets the callback for the ServerCallback object

    @param callback (Player, ...any) -> (...any)
    @param options Options
    @return ServerCallback
]=]
function ServerCallback:setCallback(callback)
    self._callback = callback

    if callback then
        for _, thread in pairs(self._queue) do
            task.spawn(thread, true)
        end
    end

    table.clear(self._queue)
end

--[=[
    Flushes any pending requests
]=]
function ServerCallback:flush()
    for _, thread in pairs(self._queue) do
        task.spawn(thread, false, "Request was flushed on the server")
    end

    table.clear(self._queue)
end

--[=[
    Returns a promise that resolves with the client response

    @param client Player
    @param ... any
    @return Promise
]=]
function ServerCallback:callClientAsync(client, ...)
    return Promise.try(function(...)
        -- return NetPass.decode(self._remote:InvokeClient(client, NetPass.encode(...)))
        return self._remote:InvokeClient(client, ...)
    end, ...)
end

--[=[
    Flushes any pending requests and prepares the ServerCallback object for garbage collection
]=]
function ServerCallback:destroy()
    self:flush()
    self._cleaner:destroy()
end

return ServerCallback