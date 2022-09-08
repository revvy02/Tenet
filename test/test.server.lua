local package = game.ServerScriptService.Tenet

package.Parent = game.ReplicatedStorage.Packages

require(package.Parent.TestEZ).TestBootstrap:run({
    package.Primitives.Client["ClientSignal.spec"],
    package.Primitives.Server["ServerSignal.spec"],

    package.Primitives.Client["ClientCallback.spec"],
    package.Primitives.Server["ServerCallback.spec"],

    package.Primitives.Client["ClientBroadcast.spec"],
    package.Primitives.Server["ServerBroadcast.spec"],

    package.Primitives.Client["AtomicChannelClient.spec"],
    package.Primitives.Server["AtomicChannelServer.spec"],

    package.Primitives.Client["NonatomicChannelClient.spec"],
    package.Primitives.Server["NonatomicChannelServer.spec"],

    package.Primitives.Client["ClientNetwork.spec"],
    package.Primitives.Server["ServerNetwork.spec"],

    package.Middleware.Inbound.Client["clientInstanceKeyDecoder.spec"],
    package.Middleware.Inbound.Server["serverInstanceKeyDecoder.spec"],

    package.Middleware.Outbound.Client["clientInstanceKeyEncoder.spec"],
    package.Middleware.Outbound.Server["serverInstanceKeyEncoder.spec"],

    package.Middleware.Inbound.Server["serverRuntimeTypechecker.spec"],

    package.Middleware.Inbound.Server["serverNetworkBlocker.spec"],
})