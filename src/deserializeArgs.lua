local function deserializeTable(metadata, arg)
    for _, info in metadata do
        if typeof(info.v) == "table" then
            arg[info.k] = deserializeTable(info.m, info.v)
        else
            arg[info.k] = info.v
        end
    end
end

local function deserializeArgs(metadata, ...)
    local deserialized = {}

    for index, arg in {...} do
        if typeof(arg) == "table" then
            deserialized[index] = deserializeTable(metadata[index], arg)
        else
            deserialized[index] = arg
        end
    end

    return table.unpack(deserialized)
end

return deserializeArgs