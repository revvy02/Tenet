return function(config)
    local info = {}

    task.spawn(function()
        while true do
            task.wait(config.window)
            table.clear(info)
        end
    end)

    return function(nextMiddleware, networkElement)
        return function(player, ...)
            local requestsLeft = info[player]

            if requestsLeft == 0 then
                if config.onDropped then
                    config.onDropped(networkElement, player, ...)
                end

                return
            elseif requestsLeft == nil then
                requestsLeft[player] = config.budget - 1
            elseif requestsLeft > 0 then
                requestsLeft[player] = requestsLeft - 1
            end

            if config.onPassed then
                config.onPassed(networkElement, player, ...)
            end
            
            return nextMiddleware(player, ...)
        end
    end
end