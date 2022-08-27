local NetPass = require(script.Parent.Parent.Parent.Parent.Parent.NetPass)

local function instanceKeyEncoder()
    return function(nextMiddleware)
        return function(...)
            return nextMiddleware(NetPass.encode(...))
        end
    end
end

return instanceKeyEncoder