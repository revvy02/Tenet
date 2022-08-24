local function runtimeTypechecker(typecheck, onFail)
    return function(nextMiddleware, clientElement)
        return function(client, ...)
            if typecheck(...) then
                return nextMiddleware(client, ...)
            else
                task.spawn(onFail, clientElement, client, ...)
                error("typecheck failed")
            end
        end
    end
end

return runtimeTypechecker