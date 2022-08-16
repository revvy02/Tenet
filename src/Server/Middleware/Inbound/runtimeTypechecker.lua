local function runtimeTypechecker(typecheck, onFail)
    return function(nextMiddleware, clientElement)
        return function(client, ...)
            if typecheck(...) then
                return nextMiddleware(client, ...)
            else
                onFail(clientElement, client, ...)
                error("[Stellar.Middleware.Server.Inbound.runtimeTypechecker] Typecheck failed")
            end
        end
    end
end

return runtimeTypechecker