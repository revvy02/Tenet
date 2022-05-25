local Promise = require(script.Parent.Parent.Parent.Promise)
local Cleaner = require(script.Parent.Parent.Parent.Cleaner)
local Slick = require(script.Parent.Parent.Parent.Slick)

local DynamicStore = require(script.Parent.DynamicStore)
local ClientSignal = require(script.Parent.ClientSignal)

local actionHandlers = {
    dispatch = function(self, owner, key, reducer, ...)
        self:get(owner):dispatch(key, reducer, ...)
    end,

    load = function(self, owner, key, value)
        self:get(owner):load(key, value)
    end,

    unload = function(self, owner, key)
        self:get(owner, key)
    end,

    setReducers = function(self, owner, module)
        self:get(owner):setReducers(require(module))
    end,

    stream = function(self, owner, ...)
        self.streaming:fire(owner)
        self.streamed:fire(owner, self._cleaner:set(owner, DynamicStore.new(...)))
    end,

    unstream = function(self, owner)
        self.unstreaming:fire(owner, self._cleaner:get(owner))
        self._cleaner:finalize(owner)
        self.unstreamed:fire(owner)
    end,
}

--[=[
    ClientDynamicStream class

    @class ClientDynamicStream
]=]
local ClientDynamicStream = {}
ClientDynamicStream.__index = ClientDynamicStream

--[=[
    Creates a new ClientDynamicStream

    @param remotes table
    @return ClientDynamicStream
]=]
function ClientDynamicStream.new(remotes)
    local self = setmetatable({}, ClientDynamicStream)

    self._cleaner = Cleaner.new()

    self._clientSignal = self._cleaner:add(ClientSignal.new(remotes))

    --[=[
        Signal that gets fired once a store begins streaming

        @prop streaming Signal
        @readonly
        @within ClientDynamicStream
    ]=]
    self.streaming = self._cleaner:add(Slick.Signal.new())

    --[=[
        Signal that gets fired once a store is streamed in

        @prop streamed Signal
        @readonly
        @within ClientDynamicStream
    ]=]
    self.streamed = self._cleaner:add(Slick.Signal.new())

    --[=[
        Signal that gets fired once a store begins unstreaming

        @prop unstreaming Signal
        @readonly
        @within ClientDynamicStream
    ]=]
    self.unstreaming = self._cleaner:add(Slick.Signal.new())

    --[=[
        Signal that gets fired once a store is unstreamed out

        @prop unstreamed Signal
        @readonly
        @within ClientDynamicStream
    ]=]
    self.unstreamed = self._cleaner:add(Slick.Signal.new())

    self._cleaner:add(self._clientSignal:connect(function(action, owner, ...)
        actionHandlers[action](self, owner, ...)
    end))

    return self
end

--[=[
    Returns whether or not the passed argument is a ClientDynamicStream or not

    @param obj any
    @return bool
]=]
function ClientDynamicStream.is(obj)
    return typeof(obj) == "table" and getmetatable(obj) == ClientDynamicStream
end

--[=[
    Gets the DynamicStore instance for the passed owner if it exists

    @param owner any
    @return DynamicStore
]=]
function ClientDynamicStream:get(owner)
    return self._cleaner:get(owner)
end

--[=[
    Returns a promise that resolves once a DynamicStore is streamed for the passed owner

    @param owner any
    @return Promise
]=]
function ClientDynamicStream:streamedAsync(owner)
    if self:get(owner) then
        return Promise.resolve()
    end

    return Promise.fromEvent(self.streamed, function(streamedOwner)
        return streamedOwner == owner
    end)
end

--[=[
    Prepares the ClientDynamicStream for garbage collection
]=]
function ClientDynamicStream:destroy()
    self._cleaner:destroy()
    self.destroyed = true
end

return ClientDynamicStream