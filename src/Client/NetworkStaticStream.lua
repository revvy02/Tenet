local StaticStore = require(script.Parent.StaticStore)
local Stream = require(script.Parent.Stream)

local NetworkStaticStream = {}
NetworkStaticStream.__index = NetworkStaticStream

function NetworkStaticStream.new(options)
    local self = setmetatable({}, NetworkStaticStream)

    self._stream = Stream.new(options, StaticStore)

    return self
end

function NetworkStaticStream:get(owner)
    return self._stream:get(owner)
end

function NetworkStaticStream:await(owner)
    return self._stream:await(owner)
end

function NetworkStaticStream:destroy()
    self._stream:destroy()
end

return NetworkStaticStream