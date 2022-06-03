local package = game.ServerScriptService.Stellar

package.Parent = game.ReplicatedStorage.Packages

require(package.Parent.TestEZ).TestBootstrap:run({
    package.Client["ClientCallback.spec"],
    package.Server["ServerCallback.spec"],
    
    package.Client["ClientSignal.spec"],
    package.Server["ServerSignal.spec"],

    package.Client["ClientStaticStream.spec"],
    package.Server["ServerStaticStream.spec"],

    package.Client["StaticStoreClient.spec"],
    package.Server["StaticStoreServer.spec"],

     --[[
    package.Client["DynamicStoreClient.spec"],
    package.Client["ClientDynamicStream.spec"],
    
    package.Client["ClientStaticStream.spec"],

    
    package.Client["ClientStaticStore.spec"],
    package.Client["ClientChannelStream.spec"],
    package.Client["ClientStaticStream.spec"],

    package.Server["ServerSignal.spec"],
    package.Server["ServerCallback.spec"],
    package.Server["ServerChannelStore.spec"],
    package.Server["ServerStaticStore.spec"],
    package.Server["ServerChannelStream.spec"],
    package.Server["ServerStaticStream.spec"],--]]
})
