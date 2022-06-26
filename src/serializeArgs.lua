local function cloneTable(tab)
    local new = {}

    for key, value in tab do
        if typeof(key) == "Instance" then
            continue
        end

        if typeof(value) == "table" then
            value = cloneTable(value)
        end

        new[key] = value
    end

    return new
end

local function getMetadata(tab)
    local metadata = {}

    for key, value in tab do
        local info = {}

        if typeof(key) == "Instance" then
            info.k = key
            info.v = value
        end

        if typeof(value) == "table" then
            info.m = getMetadata(value)
        end

        table.insert(metadata, info)
    end

    return metadata
end

local function serializeArgs(...)
    local metadata = {}
    local serialized = {}

    for index, arg in {...} do
        if typeof(arg) == "table" then
            serialized[index] = arg
        else
            metadata[index] = getMetadata(arg)
            serialized[index] = cloneTable(arg)
        end
    end

    return metadata, table.unpack(serialized)
end

return serializeArgs