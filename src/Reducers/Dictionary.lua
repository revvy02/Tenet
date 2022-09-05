local Value = require(script.Parent.Value)

local Dictionary = {
    setIndex = function(old, index, value)
        local new = table.clone(old)

        new[index] = value

        return new
    end,

    setValue = Value.setValue,
}

return Dictionary