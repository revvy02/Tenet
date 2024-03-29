local Value = require(script.Parent.Value)

local List = {
    insertValue = function(old, value, index)
        local new = table.clone(old)

        if index then
            table.insert(new, index, value)
        else
            table.insert(new, value)
        end

        return new
    end,

    removeIndex = function(old, index)
        local new = table.clone(old)

        table.remove(new, index)

        return new
    end,

    removeValue = function(old, value)
        local index = table.find(old, value)

        if index then
            local new = table.clone(old)

            table.remove(new, index)

            return new
        end

        return old
    end,

    setValue = Value.setValue,
}

return List