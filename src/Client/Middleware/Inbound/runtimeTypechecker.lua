local function runtimeTypechecker(typecheck, onFail)
    return function(nextMiddleware, clientElement)
        return function(...)
            if typecheck(...) then
                return nextMiddleware(...)
            else
                task.spawn(onFail, clientElement, ...)
                error("typecheck failed")
            end
        end
    end
end

return runtimeTypechecker