local Client = {
    clientBatchedRequestReceiver = require(script.clientBatchedRequestReceiver),
    clientInstanceKeyDecoder = require(script.clientInstanceKeyDecoder),
    clientRuntimeTypechecker = require(script.clientRuntimeTypechecker),
}

return Client