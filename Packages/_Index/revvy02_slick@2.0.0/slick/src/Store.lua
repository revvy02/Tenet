local WEAK_MT = {__mode = "v"}

local Cleaner = require(script.Parent.Parent.Cleaner)
local TrueSignal = require(script.Parent.Parent.TrueSignal)

local Reducers = require(script.Parent.Reducers)

local function freezeValue(value)
    if typeof(value) == "table" and not table.isfrozen(value) then
        table.freeze(value)
    end
end

local function freezeState(state)
    if not table.isfrozen(state) then
        table.freeze(state)
    end

    for _, value in state do
        freezeValue(value)
    end
end

local function immutableSet(state, key, value)
    local new = table.clone(state)

    freezeValue(value)

    new[key] = value

    return new
end

--[=[
    Store class that holds many values that can be changed by a set of reducers

    @class Store
]=]
local Store = {}
Store.__index = Store

--[=[
    Attempts to add the old state to the history depending on the depth and returns true if successful

    @private
    @param oldState table
]=]
function Store:_tryHistory(oldState)
    local depth = self:getDepth()

    if depth > 0 then
        local history = table.clone(self._history)
        
        table.insert(history, 1, oldState)
        
        if #history > depth then
            table.remove(history, #history)
        end

        table.freeze(history)

        self._history = history
    end
end

--[=[
    Attempts to trim the history of the store depending on depth and current history and returns true if successful

    @private
]=]
function Store:_trimHistory()
    local depth = self:getDepth()
    local history = self._history
    local n = #history

    if depth < n then
        local new = table.clone(history)

        for i = depth + 1, n do
            new[i] = nil
        end

        table.freeze(new)
        self._history = new
    end
end

--[=[
    Attempts to find a changed signal for a key and generate it if generate is true

    @private
    @param key any
    @param generate bool
]=]
function Store:_findChangedSignal(key, generate)
    local changedSignals = self._changedSignals
    local changedSignal = changedSignals[key]

    if not changedSignal and generate then
        changedSignal = TrueSignal.new()
        changedSignals[key] = changedSignal
    end

    return changedSignal
end

--[=[
    Attempts to find a reduced signal for a key and its reducer and generate it if generate is true

    @private
    @param key any
    @param reducer string
    @param generate bool
]=]
function Store:_findReducedSignal(reducer, key, generate)
    local reducedSignals = self._reducedSignals
    local keySignals = reducedSignals[key]

    if not keySignals then
        if not generate then
            return
        end

        keySignals = setmetatable({}, WEAK_MT)
        reducedSignals[key] = keySignals
    end

    local reducedSignal = keySignals[reducer]

    if not reducedSignal and generate then
        reducedSignal = TrueSignal.new()
        keySignals[reducer] = reducedSignal
    end

    return reducedSignal
end

--[=[
    Creates a new Store object

    @param initial? table
    @param reducers? table
    @return Store
]=]
function Store.new(initial, reducers)
    local self = setmetatable({}, Store)

    self._depth = 0
    self._history = {}

    self._state = initial or {}
    freezeState(self._state)
    
    self._cleaner = Cleaner.new()
    self._reducers = reducers or Reducers.Standard

    self._reducedSignals = setmetatable({}, WEAK_MT)
    self._changedSignals = setmetatable({}, WEAK_MT)

    self.changed = self._cleaner:give(TrueSignal.new())
    self.reduced = self._cleaner:give(TrueSignal.new())
    
    return self
end

--[=[
    Sets how much history is tracked and removes any excess if the history size exceeds the depth

    @param depth number
]=]
function Store:setDepth(depth)
    if self._depth ~= depth then
        self._depth = depth
        self:_trimHistory()
    end
end

--[=[
    Gets the depth of the store

    @return number
]=]
function Store:getDepth()
    return self._depth
end

--[=[
    Gets the history of the store as a table

    @return table
]=]
function Store:getHistory()
    return self._history
end

--[=[
    Sets the state key to the value without firing any events (should be used to initialize the store)

    @param key any
    @param value any
]=]
function Store:rawsetValue(key, value)
    self._state = immutableSet(self._state, key, value)
end

--[=[
    Sets the state of the store without firing any events (should be used to initialize the store)

    @param state table
]=]
function Store:rawsetState(state)
    freezeState(state)
    self._state = state
end

--[=[
    Sets the reducers for the store

    @param reducers table
]=]
function Store:setReducers(reducers)
    self._reducers = reducers
end

--[=[
    Gets the value of the key in the store

    @param key any
]=]
function Store:getValue(key)
    return self._state[key]
end

--[=[
    Returns the state of the store

    @return table
]=]
function Store:getState()
    return self._state
end

--[=[
    Dispatches args to the reducer for a key

    @param key any
    @param reducer string
    @param ... any
]=]
function Store:dispatch(reducer, key, ...)
    local reduce = self._reducers[reducer]

    assert(reduce, string.format("\"%s\" is not a valid reducer for \"%s\"", reducer, key))

    local oldState = self._state
    local oldValue = oldState[key]
    local newValue = reduce(oldValue, ...)

    if newValue == oldValue then
        return
    end

    local newState = immutableSet(oldState, key, newValue)

    self._state = newState
    self:_tryHistory(oldState)

    self.changed:fire(key, newState, oldState)
    self.reduced:fire(reducer, key, ...)

    -- handle direct key change and reduced signals
    local changedSignal = self:_findChangedSignal(key, false)

    if changedSignal then
        changedSignal:fire(newValue, oldValue)
    end
   
    local reducedSignal = self:_findReducedSignal(reducer, key, false)
       
    if reducedSignal then
        reducedSignal:fire(...)
    end
end

--[=[
    Returns a reduced signal that will be fired if that reducer is used on the key

    @param key any
    @param reducer any
    @return TrueSignal
]=]
function Store:getReducedSignal(reducer, key)
    return self:_findReducedSignal(reducer, key, true)
end

--[=[
    Returns a signal that will be fired if the passed key value is changed
    
    @param key any
    @return TrueSignal
]=]
function Store:getChangedSignal(key)
    return self:_findChangedSignal(key, true)
end

--[=[
    Cleans up the store object and sets destroyed field to true
    @within Store
]=]
function Store:destroy()
    for _, signal in pairs(self._changedSignals) do
        signal:destroy()
    end

    for _, signals in pairs(self._reducedSignals) do
        for _, signal in pairs(signals) do
            signal:destroy()
        end
    end

    self._cleaner:destroy()
end

return Store