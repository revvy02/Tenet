local Dictionary = {
    setIndex = function(old, index, value)
        local new = table.clone(old)

        new[index] = value

        return new
    end,
}

return Dictionary