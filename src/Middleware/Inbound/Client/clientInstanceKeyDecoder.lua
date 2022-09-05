local NetPass = require(script.Parent.Parent.Parent.Parent.Parent.NetPass)

local function clientInstanceKeyDecoder()
    return function(nextMiddleware)
        return function(...)
            return nextMiddleware(NetPass.decode(...))
        end
    end
end

return clientInstanceKeyDecoder