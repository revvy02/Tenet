local function runtimeTypechecker(typecheck, tag)
    return function(nextMiddleware, primitive, log)
        return function(client, ...)
            if typecheck(...) then
                return nextMiddleware(client, ...)
            end

            if log then
                log("serverRuntimeTypechecker violation", {
                    tag = tag,
                    args = {...},
                    client = client,
                    primitive = primitive,
                    typecheck = typecheck,

                })
            end

            error("serverRuntimeTypechecker violation")
        end
    end
end

return runtimeTypechecker