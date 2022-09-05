local NetPass = require(script.Parent.Parent.Parent.Parent.Parent.NetPass)

local function clientInstanceKeyEncoder()
    return function(nextMiddleware)
        return function(...)
            return nextMiddleware(NetPass.encode(...))
        end
    end
end

return clientInstanceKeyEncoder