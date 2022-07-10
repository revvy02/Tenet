local function stringify(tab: table, sort: ((any, any) -> boolean)?, indent: boolean?): string
    local entries  = {}

    local function format(arg)
        return if typeof(arg) == "table" then stringify(arg, sort, indent) elseif typeof(arg) == "string" then string.format("\"%s\"", arg) else tostring(arg)
    end

    for key, value in tab do
        table.insert(entries, {
            str = if typeof(key) == "number" then string.format("%s", format(value)) else string.format("[%s]: %s", format(key), format(value)),
            key = key,
            value = value,
        })
    end

    table.sort(entries, sort or function(a, b)
        local aKeyType = typeof(a.key)
        local bKeyType = typeof(b.key)

        if (aKeyType == "number" and bKeyType ~= "number")
        or (aKeyType == "string" and bKeyType ~= "number" and bKeyType ~= "string")
        or (aKeyType == "Instance" and bKeyType ~= "number" and bKeyType ~= "string" and bKeyType ~= "Instance") then
            return true
        end

        return a.str < b.str
    end)

    local strings = {}

    for _, entry in entries do
        table.insert(strings, entry.str)
    end

    return string.format("{%s}", table.concat(strings, ", "))
end


return stringify