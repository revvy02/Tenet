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
function ClientCallback.new(remotes)
    local self = setmetatable({}, ClientCallback)

    self._cleaner = Cleaner.new()

    self._queue = {}
    self._remote = remotes.remoteFunction

    self._remote.OnClientInvoke = function(...)
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

--[=[
    Returns whether or not the passed argument is a ClientCallback or not

    @param obj any
    @return bool
]=]
function ClientCallback.is(obj)
    return typeof(obj) == "table" and getmetatable(obj) == ClientCallback
end

--[=[
    Sets the client handler callback

    @param callback function
]=]
function ClientCallback:setCallback(callback)
    if callback then
        for _, request in pairs(self._queue) do
            task.spawn(request.thread, callback(table.unpack(request.args)))
        end
    end

    self._callback = callback
end

--[=[
    Flushes any pending requests on the client
]=]
function ClientCallback:flush()
    for _, request in pairs(self._queue) do
        task.cancel(request.thread)
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