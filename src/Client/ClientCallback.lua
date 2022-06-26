local Promise = require(script.Parent.Parent.Parent.Promise)
local Cleaner = require(script.Parent.Parent.Parent.Cleaner)

--[=[
    ClientCallback class

    @class ClientCallback
]=]
local ClientCallback = {}
ClientCallback.__index = ClientCallback

--[=[
    Creates a new ClientCallback

    @param remotes table
    @return ClientCallback
]=]
function ClientCallback.new(remoteFunction)
    local self = setmetatable({}, ClientCallback)

    self._cleaner = Cleaner.new()

    self._queue = {}
    self._remote = remoteFunction

    self._remote.OnClientInvoke = function(...)
        if not self._callback then
            warn("ClientCallback has no callback set, so request is being queued")
            
            table.insert(self._queue, coroutine.running())

            assert(coroutine.yield())
        end

        return self._callback(...)
    end

    return self
end

--[=[
    Sets the client handler callback

    @param callback function
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
    Flushes any pending requests on the client
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
        return self._remote:InvokeServer(...)
    end, ...)
end

--[=[
    Prepares the ClientCallback instance for garbage collection

    @private
]=]
function ClientCallback:destroy()
    self:flush()
    self._cleaner:destroy()
    self.destroyed = true
end

return ClientCallback