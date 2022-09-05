local NetPass = require(script.Parent.Parent.Parent.Parent.Parent.NetPass)

local function serverInstanceKeyDecoder()
    return function(nextMiddleware)
        return function(client, ...)
            return nextMiddleware(client, NetPass.decode(...))
        end
    end
end

return serverInstanceKeyDecoder