local function runtimeTypechecker(typecheck, onFail)
    return function(nextMiddleware, clientElement)
        return function(...)
            if typecheck(...) then
                return nextMiddleware(...)
            else
                onFail(clientElement, ...)
                error("[Stellar.Client.Inbound.runtimeTypechecker] Typecheck failed")
            end
        end
    end
end

return runtimeTypechecker