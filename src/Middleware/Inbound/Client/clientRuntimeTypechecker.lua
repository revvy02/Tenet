local function runtimeTypechecker(typecheck, onFail)
    return function(nextMiddleware, clientElement)
        return function(...)
            if typecheck(...) then
                return nextMiddleware(...)
            else
                task.spawn(onFail, clientElement, ...)
                error("clientRuntimeTypechecker violation")
            end
        end
    end
end

return runtimeTypechecker