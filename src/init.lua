--[[
    -- 1
    A static store where keys cannot be subscribed to. Good if clients don't know what keys to subscribe to

    -- 2
    A channelstore where players can be subscribed to keys. Good if clients know what keys to subscribe to
    (need to have sanity checks on server that will verify the keys that are subscribed to)

    -- 3
    A stream of static stores that have "owners".

    -- 4
    A stream of channel stores that have "owners".


]]