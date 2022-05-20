return function(window, budget)
    local requests = {}

    task.spawn(function()
        while true do
            task.wait(window)
            table.clear(requests)
        end
    end)

    return function(nextMiddleware, networkElement)
        return function(player, ...)
            local requestsLeft = requests[player]

            if requestsLeft == 0 then
                return
            elseif requestsLeft == nil then
                requestsLeft[player] = budget - 1
            elseif requestsLeft > 0 then
                requestsLeft[player] = requestsLeft - 1
            end

            return nextMiddleware(player, ...)
        end
    end
end