local Stellar = {
    Primitives = require(script.Primitives),
    Definitions = require(script.Definitions),
    Reducers = require(script.Reducers),
    Middleware = require(script.Middleware),
    Network = require(script.Network),
}

local t

Stellar.Network.Server:createServerSignal("ContentProvider", {
    inboundMiddleware = {
        Stellar.Middleware.Server.Inbound.netpassDecode,
        Stellar.Middleware.Server.Inbound.runtimeTypecheck(t.tuple(t.string, t.boolean)),
    },
    outboundMiddleware = {
        Stellar.Middleware.Server.Outbound.netpassEncode,
    },
})

Stellar.Network.Client:createClientSignal("ContentProvider", {
    inboundMiddleware = {
        Stellar.Middleware.Client.Inbound.netpassDecoder(),
        Stellar.Middleware.Server.Inbound.runtimeTypechecker(t.tuple(t.string, t.boolean)),
    },
    outboundMiddleware = {
        Stellar.Middleware.Client.Outbound.netpassEncoder(),
    },
})

Stellar.Client.Network:createServerSignal("ContentProvider", {
    inboundMiddleware = {
        Stellar.Middleware.Server.Inbound.netpassDecoder(),
        Stellar.Middleware.Server.Inbound.runtimeTypechecker(t.tuple(t.string, t.boolean)),
    },
    outboundMiddleware = {
        Stellar.Middleware.Server.Outbound.netpassEncode,
    },
})

Stellar.Client.Network:createClientSignal("ContentProvider", {
    inboundMiddleware = {
        Stellar.Client.Middleware.Inbound.netpassDecoder(),
        Stellar.Server.Middleware.Inbound.runtimeTypechecker(t.tuple(t.string, t.boolean)),
    },
    outboundMiddleware = {
        Stellar.Client.Middleware.Outbound.netpassEncoder(),
    },
})

local contentProvider = Stellar.Server.Network:createServerBroadcast("ContentProvider")

contentProvider:createNonatomicChannel("Content", {})





