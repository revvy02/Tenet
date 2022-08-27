local NetPass = require(script.Parent.Parent.Parent.Parent.Parent.NetPass)

local function instanceKeyDecoder()
    return function(nextMiddleware)
        return function(client, ...)
            return nextMiddleware(client, NetPass.decode(...))
        end
    end
end

return instanceKeyDecoder