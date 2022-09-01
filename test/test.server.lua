local package = game.ServerScriptService.Stellar

package.Parent = game.ReplicatedStorage.Packages

require(package.Parent.TestEZ).TestBootstrap:run({
    package.Client.Primitives["ClientCallback.spec"],
    package.Server.Primitives["ServerCallback.spec"],
    
    package.Client.Primitives["ClientSignal.spec"],
    package.Server.Primitives["ServerSignal.spec"],

    package.Client.Primitives["ClientBroadcast.spec"],
    package.Server.Primitives["ServerBroadcast.spec"],
    
    package.Client.Primitives["AtomicChannelClient.spec"],
    package.Server.Primitives["AtomicChannelServer.spec"],
    
    package.Client.Primitives["NonatomicChannelClient.spec"],
    package.Server.Primitives["NonatomicChannelServer.spec"],
})