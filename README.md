# Tenet
<div align="center">
	<h1>Tenet</h1>
	<p>Roblox networking library</p>
	<a href="https://revvy02.github.io/Tenet/"><strong>View docs</strong></a>
</div>
<!--moonwave-hide-before-this-line-->

## Install using Package Manager
[Tenet can be installed as a package from Wally](https://wally.run/package/revvy02/tenet)

## Primitives 
All primitives have a server and client variation. They wrap remote but client variations
represent the client API whereas the server variations only includes the server API.

### Network
Networks serve as an access point for any other primitives. Sometime's it's beneficial
to split up networking behavior in your game into multiple network objects, but it's also
possible to just use one. 
**On the server**
```lua
local serverNetwork = Tenet.Primitives.Server.ServerNetwork.new("network")
-- You can add signals, callbacks, or broadcasts to the network and they can be accessed by the client
serverNetwork:createServerSignal("message"):fireAllClients("hello from the server")
```
**On the client**
```lua
-- make sure the network names match as this is what maps remotes and correctly wraps network objects
local clientNetwork = Tenet.Primitives.Client.ClientNetwork.new("network")

clientNetwork:getClientSignalAsync("message"):expect():connect(function(message)
	print(message)
end)
```
**Expected Output on server:**
```
hello from the server
```

### Callback
Callbacks are analagous to RemoteFunctions, but with a promise based API and the ability to flush pending requests
**On the server**
```lua
local serverCallback = serverNetwork:createServerCallback("getData")

serverCallback:setCallback(function(client, ...)pp
	print(client, ...)

	return "hello from the server"
end)
```
**On the client**
```lua
local clientCallback = clientNetwork:getClientCallbackAsync("getData"):expect()

local response = clientCallback:callServerAsync("hello"):expect()

print(response)
```
**Expected Output on server:**
```
Player1 hello
```
**Expected Output on client:**
```
hello from the server
```
### Signal
Similar to Callbacks, Signals are analagous to RemoteEvents but with promise based API and the ability to flush pending requests
**On the server**
```lua

```
**On the client**
```lua

```
### Broadcast
Broadcasts are one of the more significant features of 
**On the server**
```lua

```
**On the client**
```lua

```

## Middleware
Middleware serves as the entry and exit point for all signal and callback objects,.
You could pretty much implement any behavior or optimization you want including runtime typechecking,
logging, request batching, ratelimiting, etc. Some of these are already included with Tenet.

### Inbound

### Outbound