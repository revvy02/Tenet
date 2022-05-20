local ChannelStore = require(script.Parent.ChannelStore)
local Stream = require(script.Parent.Stream)

local NetworkChannelStream = {}
NetworkChannelStream.__index = NetworkChannelStream

function NetworkChannelStream.new(options)
    local self = setmetatable({}, NetworkChannelStream)

    self._stream = Stream.new(options, ChannelStore)

    return self
end

function NetworkChannelStream:get(owner)
    return self._stream:get(owner)
end

function NetworkChannelStream:await(owner)
    return self._stream:await(owner)
end

function NetworkChannelStream:destroy()
    self._stream:destroy()
end

return NetworkChannelStream