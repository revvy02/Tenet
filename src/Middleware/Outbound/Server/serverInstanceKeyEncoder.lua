local NetPass = require(script.Parent.Parent.Parent.Parent.Parent.NetPass)

local function serverInstanceKeyDecoder()
    return function(nextMiddleware)
        return function(client, ...)
            return nextMiddleware(client, NetPass.encode(...))
        end
    end
end

return serverInstanceKeyDecoder