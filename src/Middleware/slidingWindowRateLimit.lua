return function(config)
    local info = {}

    return function(nextMiddleware, networkElement)
        return function(player, ...)
            local data = info[player]
            local currTime = os.clock()

            if not data then
                data = {
                    currTime = os.clock(),
                    preCount = config.budget,
                    currCount = 0,
                }

                info[player] = data
            end

            if currTime - data.currTime > config.window then
                data.currTime = currTime
                data.preCount = data.currCount
                data.currCount = 0
            end

            local ec = (data.preCount * (config.budget - (currTime - data.currTime)) / config.window) + data.currCount

            if ec <= config.budget then
                data.currCount += 1

                if config.onSuccess then
                    config.onSuccess()
                end
            
                return nextMiddleware(player, ...)
            end

            if config.onFailure then
                config.onFailure()
            end
        end
    end, function()
        table.clear(info)
    end
end