local function networkBlocker(tag)
    return function(_, primitive, log)
        return function(client, ...)
            if log then
                task.spawn(log, "serverNetworkBlocker violation", {
                    tag = tag,
                    args = {...},
                    client = client,
                    primitive = primitive,
                })
            end

            error("serverNetworkBlocker violation")
        end
    end
end

return networkBlocker