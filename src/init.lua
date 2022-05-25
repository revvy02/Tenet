--[[
    ClientCallback behavior to define

    what happens to request to client when client disconnects before response
    what happens to request to server when client disconnects before response

]]

local Stellar = {
    Client = require(script.Client),
    Server = require(script.Server),
    Middleware = require(script.Middleware),
    StoreBehavior = require(script.StoreBehavior),
}