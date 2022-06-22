local ReplicatedStorage = game:GetService("ReplicatedStorage")
--[[
    ClientCallback behavior to define

    what happens to request to client when client disconnects before response
    what happens to request to server when client disconnects before response

]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

if game:GetService("RunService"):IsServer() then
    local folder = Instance.new("Folder")
    folder.Name = "StellarNetwork"
    folder.Parent = ReplicatedStorage
end

local Stellar = {
    Client = require(script.Client).new(),
    Server = require(script.Server).new(),
    Middleware = require(script.Middleware),
}