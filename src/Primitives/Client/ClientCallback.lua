local Promise = require(script.Parent.Parent.Parent.Parent.Promise)
local Cleaner = require(script.Parent.Parent.Parent.Parent.Cleaner)
local NetPass = require(script.Parent.Parent.Parent.Parent.NetPass)

--[=[
    RemoteFunction client wrapper class that implements logging and middleware

    @class ClientCallback
]=]
local ClientCallback = {}
ClientCallback.__index = ClientCallback

--[=[
    Flushes any requests and prepares the ClientCallback object for garbage collection

    @private
]=]
function ClientCallback:_destroy()
    self:flush()
    self._cleaner:destroy()
end

--[=[
    Constructs a new ClientCallback object

    @param remoteFunction RemoteFunction
    @param options Options
    @return ClientCallback
]=]
function ClientCallback.new(remoteFunction, options)
    local self = setmetatable({}, ClientCallback)

    self._cleaner = Cleaner.new()

    self._queue = {}
    self._remote = remoteFunction

    local onClientInvoke = function(...)
        if not self._callback then
            warn("ClientCallback has no callback set, so request is being queued")
            
            table.insert(self._queue, coroutine.running())

            assert(coroutine.yield())
        end

        return self._callback(...)
    end

    if options then
        if options.inbound then
            for i = #options.inbound, 1, -1 do
                local nextOnClientInvoke, cleanup = options.inbound[i](onClientInvoke, self)
                onClientInvoke = nextOnClientInvoke

                if cleanup then
                    self._cleaner:give(cleanup)
                end
            end
        end

        if options.outbound then
            local unboundCallServerAsync = self.callServerAsync

            local callServerAsync = function(...)
                return unboundCallServerAsync(self, ...)
            end

            for i = #options.outbound, 1, -1 do
                local nextCallServerAsync, cleanup = options.outbound[i](callServerAsync, self)
                callServerAsync = nextCallServerAsync

                if cleanup then
                    self._cleaner:give(cleanup)
                end
            end

            self.callServerAsync = function(_, ...)
                return callServerAsync(...)
            end
        end
    end
    
    self._remote.OnClientInvoke = function(...)
        -- return NetPass.encode(onClientInvoke(NetPass.decode(...)))
        return onClientInvoke(...)
    end

    return self
end

--[=[
    Sets the client handler callback

    @param callback (...any) -> (...any)
]=]
function ClientCallback:setCallback(callback)
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
function ClientCallback:flush()
    for _, thread in pairs(self._queue) do
        task.spawn(thread, false, "Request was flushed on the client")
    end

    table.clear(self._queue)
end

--[=[
    Sends a request to the server and returns a promise that resolves with the response

    @param ... any
    @return Promise
]=]
function ClientCallback:callServerAsync(...)
    return Promise.try(function(...)
        -- return NetPass.decode(self._remote:InvokeServer(NetPass.encode(...)))
        return self._remote:InvokeServer(...)
    end, ...)
end

return ClientCallback