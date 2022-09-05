local List = require(script.Parent.List)
local Dictionary = require(script.Parent.Dictionary)
local Value = require(script.Parent.Value)

local Mixed = {
    setValue = Value.setValue,
    setIndex = Dictionary.setIndex,
    insertValue = List.insertValue,
    removeIndex = List.removeIndex,
    removeValue = List.removeValue,
}

return Mixed