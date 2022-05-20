local ProximityPromptService = game:GetService("ProximityPromptService")
local Slick = require(script.Parent.Parent.Parent.Slick)
local Cleaner = require(script.Parent.Parent.Parent.Cleaner)

local Client = {}
Client.__index = Client

local Constructors = {
    NetworkSignals = require(script.Parent.NetworkSignal),
    NetworkCallbacks = require(script.Parent.NetworkCallback),
    NetworkChannelStores = require(script.Parent.NetworkChannelStore),
    NetworkChannelStreams = require(script.Parent.NetworkChannelStream),
    NetworkStaticStores = require(script.Parent.NetworkStaticStore),
    NetworkStaticStreams = require(script.Parent.NetworkStaticStream),
}

function Client.new(directory)
    local self = setmetatable({}, Client)

    self._cleaner = Cleaner.new()
    self._elements = self._cleaner:add(Slick.Store.new())

    local function subdirectoryAdded(subdirectory)
        local subdir = subdirectory.Name

        self._elements:dispatch(subdir, "setValue", {})
        self._cleaner:set(subdir, Cleaner.new())

        local function added(object)
            local element = Constructors[subdir].new(object)
            local name = object.Name

            self._elements:dispatch(subdir, "setIndex", name, Constructors[subdir].new(element))
            self._cleaner:get(subdir):set(name, object)
        end

        local function removed(object)
            local name = object.Name

            self._elements:dispatch(subdir, "setIndex", name, nil)
            self._elements:get(subdir):finalize(object.Name)
        end

        self._cleaner:get(subdir):add(subdirectory.ChildAdded:Connect(added))
        self._cleaner:get(subdir):add(subdirectory.ChildRemoved:Connect(removed))
    end

    local function subdirectoryRemoved(subdirectory)
        self._cleaner:finalize(subdirectory.Name)
    end

    self._cleaner:add(directory.ChildAdded:Connect(subdirectoryAdded))
    self._cleaner:add(directory.ChildRemoved:Connect(subdirectoryRemoved))

    return self
end

function Client:_getElementAsync(directory, name)
    if self._elements:get(directory)[name] then
        return self._elements:get(directory)[name]
    end

    return Promise.fromEvent(self._elements:getReducedSignal(directory, "setIndex"), function(newName, element)
        return newName == name
    end):andThen(function()
        return self._elements:get(directory)[name]
    end)
end

function Client:getNetworkSignalAsync(name)
    return self:_getElementAsync("NetworkSignals", name)
end

function Client:getNetworkCallbackAsync(name)
    return self:_getElementAsync("NetworkCallbacks", name)
end

function Client:getNetworkChannelStoreAsync(name)
    return self:_getElementAsync("NetworkChannelStores", name)
end

function Client:getNetworkChannelStreamAsync(name)
    return self:_getElementAsync("NetworkChannelStreams", name)
end

function Client:getNetworkStaticStoreAsync(name)
    return self:_getElementAsync("NetworkStaticStores", name)
end

function Client:getNetworkStaticStreamAsync(name)
    return self:_getElementAsync("NetworkStaticStreams", name)
end

function Client:destroy()
    self._cleaner:destroy()
end



return Client.new()