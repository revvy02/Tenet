local NetPass

local function instanceKeyDecoder()
    return function(nextMiddleware)
        return function(...)
            return nextMiddleware(NetPass.decode(...))
        end
    end
end

return instanceKeyDecoder