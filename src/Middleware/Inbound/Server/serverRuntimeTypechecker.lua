local function runtimeTypechecker(typecheck, onFail)
    return function(nextMiddleware, serverElement, log)
        return function(client, ...)
            if typecheck(...) then
                return nextMiddleware(client, ...)
            else
                if onFail then
                    task.spawn(onFail, serverElement, client, ...)
                end

                if log then
                    log("serverRuntimeTypechecker violation", {
                        client = client,
                        typecheck = typecheck,
                        args = {...},
                        time = os.clock(),
                    })
                end

                error("serverRuntimeTypechecker violation")
            end
        end
    end
end

return runtimeTypechecker