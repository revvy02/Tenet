local Types = require(script.Parent.Types)

local function isCyclic(tab, checked)
    if checked == nil then
        checked = {}
    elseif checked[tab] then
        return true
    end

    checked[tab] = true

    for _, value in tab do
        if typeof(value) == "table" and isCyclic(value, checked) then
            return true
        end
    end

    return false
end

local function copy(tab: table): table
    local new = {}

    for key, value in tab do
        if typeof(key) == "Instance" then
            continue
        end

        if typeof(value) == "table" then
            value = copy(value)
        end

        new[key] = value
    end

    return new
end

local function hasInstanceKeys(tab: table): boolean
    for key, value in tab do
        if typeof(key) == "Instance" then
            return true
        end

        if typeof(value) == "table" and hasInstanceKeys(value) then
            return true
        end
    end

    return false
end

local function getKeyData(tab: table): Types.KeyData
    local keyData: Types.KeyData = {}
    
    for key, value in tab do
        if typeof(key) ~= "Instance" then
            continue
        end

        local pairData: Types.PairData = {
            k = key,
            v = if typeof(value) == "table" and hasInstanceKeys(value) then copy(value) else value
        }

        if typeof(value) == "table" then
            pairData.d = getKeyData(value)
        end

        table.insert(keyData, pairData)
    end

    return keyData
end

--[=[

    @function encode
    @within NetPass

    @param ... NetData
    @return MetaData, ...NetData
]=]
local function encode(...: Types.NetData): (Types.MetaData, ...Types.NetData)
    local encoded = {...}
    local metaData: Types.MetaData = {}

    for index, arg in encoded do
        if typeof(arg) == "table" then
            assert(not isCyclic(arg), "Cannot encode cyclic tables")

            if hasInstanceKeys(arg) then
                metaData[index] = getKeyData(arg)
                encoded[index] = copy(arg)
            end
        end
    end
    
    return (next(metaData) and metaData), table.unpack(encoded)
end

return encode