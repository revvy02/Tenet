local Promise = require(script.Parent.Parent.Parent.Promise)
local Cleaner = require(script.Parent.Parent.Parent.Cleaner)
local Slick = require(script.Parent.Parent.Parent.Slick)

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

    stream = function(self, owner, ...)
        self.streaming:fire(owner)
        self.streamed:fire(owner, self._cleaner:set(owner, Slick.Store.new(...)))
    end,

    unstream = function(self, owner)
        self.unstreaming:fire(owner, self._cleaner:get(owner))
        self._cleaner:finalize(owner)
        self.unstreamed:fire(owner)
    end,
}

--[=[
    ClientStaticStream class

    @class ClientStaticStream
]=]
local ClientStaticStream = {}
ClientStaticStream.__index = ClientStaticStream

--[=[
    Creates a new ClientStaticStream

    @param remotes table
    @return ClientStaticStream
]=]
function ClientStaticStream.new(remotes)
    local self = setmetatable({}, ClientStaticStream)

    self._cleaner = Cleaner.new()

    self._clientSignal = self._cleaner:add(ClientSignal.new(remotes))

    --[=[
        Signal that gets fired once a store begins streaming

        @prop streaming Signal
        @readonly
        @within ClientStaticStream
    ]=]
    self.streaming = self._cleaner:add(Slick.Signal.new())

    --[=[
        Signal that gets fired once a store is streamed in

        @prop streamed Signal
        @readonly
        @within ClientStaticStream
    ]=]
    self.streamed = self._cleaner:add(Slick.Signal.new())

    --[=[
        Signal that gets fired once a store begins unstreaming

        @prop unstreaming Signal
        @readonly
        @within ClientStaticStream
    ]=]
    self.unstreaming = self._cleaner:add(Slick.Signal.new())

    --[=[
        Signal that gets fired once a store is unstreamed out

        @prop unstreamed Signal
        @readonly
        @within ClientStaticStream
    ]=]
    self.unstreamed = self._cleaner:add(Slick.Signal.new())

    self._cleaner:add(self._clientSignal:connect(function(action, owner, ...)
        actionHandlers[action](self, owner, ...)
    end))

    return self
end

--[=[
    Returns whether or not the passed argument is a ClientStaticStream or not

    @param obj any
    @return bool
]=]
function ClientStaticStream.is(obj)
    return typeof(obj) == "table" and getmetatable(obj) == ClientStaticStream
end

--[=[
    Gets the StaticStore instance for the passed owner if it exists

    @param owner any
    @return StaticStore
]=]
function ClientStaticStream:get(owner)
    return self._cleaner:get(owner)
end

--[=[
    Returns a promise that resolves once a StaticStore is streamed for the passed owner

    @param owner any
    @return Promise
]=]
function ClientStaticStream:streamedAsync(owner)
    if self:get(owner) then
        return Promise.resolve()
    end

    return Promise.fromEvent(self.streamed, function(streamedOwner)
        return streamedOwner == owner
    end)
end

--[=[
    Prepares the ClientStaticStream for garbage collection
]=]
function ClientStaticStream:destroy()
    self._cleaner:destroy()
    self.destroyed = true
end

return ClientStaticStream