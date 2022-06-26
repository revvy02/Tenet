local Test = {
    setValue = function(_, value)
        return value
    end,

    increment = function(old, value)
        return old + value
    end,
}