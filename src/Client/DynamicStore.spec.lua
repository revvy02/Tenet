return function()
    local MockNetwork = require(script.Parent.Parent.Parent.MockNetwork)
    local Promise = require(script.Parent.Parent.Parent.Promise)

    local ClientDynamicStore = require(script.Parent.ClientDynamicStore)
    local DynamicStore = require(script.Parent.DynamicStore)

    local function withTestEnvironment(fn)
        local dynamicStore = DynamicStore.new()

        fn(dynamicStore)
        
        dynamicStore:destroy()
    end

    describe("DynamicStore.new", function()
        it("should create a new DynamicStore instance", function()
            local dynamicStore = DynamicStore.new()

            expect(dynamicStore).to.be.ok()
            expect(DynamicStore.is(dynamicStore)).to.equal(true)
    
            dynamicStore:destroy()
        end)
    end)

    describe("DynamicStore.is", function()
        it("should return true if the passed object is a DynamicStore", function()
            local dynamicStore = DynamicStore.new()
            
            expect(DynamicStore.is(dynamicStore)).to.equal(true)
            
            dynamicStore:destroy()
        end)

        it("should return false if the passed object is a DynamicStore", function()
            expect(DynamicStore.is(true)).to.equal(false)
            expect(DynamicStore.is(false)).to.equal(false)
            expect(DynamicStore.is(0)).to.equal(false)
            expect(DynamicStore.is({})).to.equal(false)
        end)
    end)

    describe("DynamicStore:get", function()
        it("should return the value of the key", function()
            local dynamicStore = DynamicStore.new()
            dynamicStore:dispatch("a", "setValue", 1)

            expect(dynamicStore:get("a")).to.equal(1)

            dynamicStore:destroy()
        end)
    end)

    describe("DynamicStore:getChangedSignal", function()
        it("should return a signal that fires with the new and old value when a key value is changed", function()
            local dynamicStore = DynamicStore.new()
            local new, old

            dynamicStore:getChangedSignal("a"):connect(function(...)
                new, old = ...
            end)

            dynamicStore:dispatch("a", "setValue", 1)
            
            expect(new).to.equal(1)
            expect(old).to.equal(nil)

            dynamicStore:destroy()
        end)
    end)

    describe("DynamicStore:getReducedSignal", function()
        it("should return a signal that fires with the reducer parameters when a key value is reduced", function()
            local dynamicStore = DynamicStore.new()
            local value

            dynamicStore:getReducedSignal("a", "setValue"):connect(function(...)
                value = ...
            end)

            dynamicStore:dispatch("a", "setValue", 1)

            expect(value).to.equal(1)

            dynamicStore:destroy()
        end)
    end)

    describe("DynamicStore:loadedAsync", function()
        it("should return a promise that resolves when the key value is loaded", function()
            local dynamicStore = DynamicStore.new()
            local promise = dynamicStore:loadedAsync("a")
            local resolved = false

            promise:andThen(function()
                resolved = true
            end)
                
            dynamicStore:load("a", 1)

            expect(resolved).to.equal(true)

            dynamicStore:destroy()
        end)
    end)
    
    describe("DynamicStore:dispatch", function()
        it("should dispatch the reducer on the key", function()
            local dynamicStore = DynamicStore.new()

            dynamicStore:dispatch("a", "setValue", 1)

            expect(dynamicStore:get("a")).to.equal(1)

            dynamicStore:destroy()
        end)

        it("should fire the reduced signal with the key, reducer, and parameters", function()
            local dynamicStore = DynamicStore.new()
            local key, reducer, value

            dynamicStore.reduced:connect(function(...)
                key, reducer, value = ...
            end)

            dynamicStore:dispatch("a", "setValue", 1)

            expect(key).to.equal("a")
            expect(reducer).to.equal("setValue")
            expect(value).to.equal(1)

            dynamicStore:destroy()
        end)

        it("should fire the changed signal with the key, new state, and old state", function()
            local dynamicStore = DynamicStore.new()
            local key, new, old

            dynamicStore.changed:connect(function(...)
                key, new, old = ...
            end)

            dynamicStore:dispatch("a", "setValue", 1)

            expect(key).to.equal("a")
            expect(new.a).to.equal(1)
            expect(old.a).to.equal(nil)

            dynamicStore:destroy()
        end)
    end)

    describe("DynamicStore:setReducers", function()
        it("should set the reducers", function()
            local dynamicStore = DynamicStore.new()
            dynamicStore:dispatch("a", "setValue", 1)

            dynamicStore:setReducers({
                increment = function(old, amount)
                    return old + amount
                end
            })

            dynamicStore:dispatch("a", "increment", 10)

            expect(dynamicStore:get("a")).to.equal(11)

            dynamicStore:destroy()
        end)
    end)

    describe("DynamicStore:load", function()
        it("should fire loaded signal with the key that loaded", function()
            local dynamicStore = DynamicStore.new()
            local loaded = false

            dynamicStore.loaded:connect(function(key)
                if key == "a" then
                    loaded = true
                end
            end)

            dynamicStore:load("a", 1)

            expect(loaded).to.equal(true)

            dynamicStore:destroy()
        end)

        it("should set initial value", function()
            local dynamicStore = DynamicStore.new()

            dynamicStore:load("a", 1)

            expect(dynamicStore:get("a")).to.equal(1)

            dynamicStore:destroy()
        end)
    end)

    describe("DynamicStore:unload", function()
        it('should fire unloaded signal with the key that unloaded', function()
            local dynamicStore = DynamicStore.new()
            local unloaded = false

            dynamicStore.unloaded:connect(function(key)
                if key == "a" then
                    unloaded = true
                end
            end)

            dynamicStore:unload("a")

            expect(unloaded).to.equal(true)
            dynamicStore:destroy()
        end)

        it("should set value to nil", function()
            local dynamicStore = DynamicStore.new()
            dynamicStore:unload("a")

            expect(dynamicStore:get("a")).to.equal(nil)
            dynamicStore:destroy()
        end)
    end)

    describe("DynamicStore:destroy", function()
        it("should disconnect any connections", function()
            local dynamicStore = DynamicStore.new()

            local function noop() end

            local connection0 = dynamicStore:getChangedSignal("a"):connect(noop)
            local connection1 = dynamicStore:getReducedSignal("a", "setValue"):connect(noop)
            local connection2 = dynamicStore.changed:connect(noop)
            local connection3 = dynamicStore.reduced:connect(noop)
            local connection4 = dynamicStore.loaded:connect(noop)
            local connection5 = dynamicStore.unloaded:connect(noop)

            dynamicStore:destroy()

            expect(connection0.connected).to.equal(false)
            expect(connection1.connected).to.equal(false)
            expect(connection2.connected).to.equal(false)
            expect(connection3.connected).to.equal(false)
            expect(connection4.connected).to.equal(false)
            expect(connection5.connected).to.equal(false)
        end)

        it("should set destroyed field to true", function()
            local dynamicStore = DynamicStore.new()

            dynamicStore:destroy()

            expect(dynamicStore.destroyed).to.equal(true)
        end)
    end)
end