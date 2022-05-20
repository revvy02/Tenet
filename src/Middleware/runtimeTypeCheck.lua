return function(config)
    return function(nextMiddleware, networkElement)
        return function(player, ...)
            local success, result = config.typecheck(...)

            if success then
                if config.onPassed then
                    config.onPassed(networkElement, result, player, ...)
                end
                return nextMiddleware(player, ...)
            elseif config.onDropped then
                config.onDropped(networkElement, result, player, ...)
            end
        end
    end
end