local package = game.ServerScriptService.Stellar

package.Parent = game.ReplicatedStorage.Packages

require(package.Parent.TestEZ).TestBootstrap:run({
    package.Client["ClientSignal.spec"],
    package.Client["ClientCallback.spec"],

    package.Client["DynamicStore.spec"],
    package.Client["ClientDynamicStore.spec"],
    package.Client["ClientDynamicStream.spec"],
    package.Client["ClientStaticStore.spec"],
    package.Client["ClientStaticStream.spec"],

    
     --[[package.Client["ClientStaticStore.spec"],
    package.Client["ClientChannelStream.spec"],
    package.Client["ClientStaticStream.spec"],

    package.Server["ServerSignal.spec"],
    package.Server["ServerCallback.spec"],
    package.Server["ServerChannelStore.spec"],
    package.Server["ServerStaticStore.spec"],
    package.Server["ServerChannelStream.spec"],
    package.Server["ServerStaticStream.spec"],--]]
})
