local Types = require(script.Parent.Types)

local function format(keyData: Types.KeyData, arg: table)
    local copy = table.clone(arg)

    for _, pairData in keyData do
        if pairData.d then
            copy[pairData.k] = format(pairData.d, pairData.v)
        else
            copy[pairData.k] = pairData.v
        end
    end

    return copy
end

--[=[
    @function decode
    @within NetPass

    @param metaData MetaData
    @param ... NetData
    @return ...NetData
]=]
local function decode(metaData: Types.MetaData, ...: Types.NetData): ...Types.NetData
    if metaData == nil then
        return ...
    end

    local decoded = {...}

    for index, arg in decoded do
        local keyData = metaData[index]

        if keyData then
            decoded[index] = format(keyData, arg)
        end
    end

    return table.unpack(decoded)
end

return decode