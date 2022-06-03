return function()
    local MockNetwork = require(script.Parent.Parent.Parent.MockNetwork)
    local Promise = require(script.Parent.Parent.Parent.Promise)

    local DynamicStoreClient = require(script.Parent.DynamicStoreClient)

    describe("DynamicStoreClient.new", function()
        it("should create a new DynamicStoreClient instance", function()
            local dynamicStoreClient = DynamicStoreClient.new()

            expect(dynamicStoreClient).to.be.a("table")
            expect(getmetatable(dynamicStoreClient)).to.equal(DynamicStoreClient)
    
            dynamicStoreClient:destroy()
        end)
    end)
    
    describe("DynamicStoreClient:get", function()
        it("should return the value of the key", function()
            local dynamicStoreClient = DynamicStoreClient.new()
            dynamicStoreClient:dispatch("a", "setValue", 1)

            expect(dynamicStoreClient:getValue("a")).to.equal(1)

            dynamicStoreClient:destroy()
        end)
    end)

    describe("DynamicStoreClient:getChangedSignal", function()
        it("should return a signal that fires with the new and old value when a key value is changed", function()
            local dynamicStoreClient = DynamicStoreClient.new()
            local new, old

            dynamicStoreClient:getChangedSignal("a"):connect(function(...)
                new, old = ...
            end)

            dynamicStoreClient:dispatch("a", "setValue", 1)
            
            expect(new).to.equal(1)
            expect(old).to.equal(nil)

            dynamicStoreClient:destroy()
        end)
    end)

    describe("DynamicStoreClient:getReducedSignal", function()
        it("should return a signal that fires with the reducer parameters when a key value is reduced", function()
            local dynamicStoreClient = DynamicStoreClient.new()
            local value

            dynamicStoreClient:getReducedSignal("a", "setValue"):connect(function(...)
                value = ...
            end)

            dynamicStoreClient:dispatch("a", "setValue", 1)

            expect(value).to.equal(1)

            dynamicStoreClient:destroy()
        end)
    end)

    describe("DynamicStoreClient:loadedAsync", function()
        it("should return a promise that resolves when the key value is loaded", function()
            local dynamicStoreClient = DynamicStoreClient.new()
            local promise = dynamicStoreClient:loadedAsync("a")
            local resolved = false

            promise:andThen(function()
                resolved = true
            end)
                
            dynamicStoreClient:load("a", 1)

            expect(resolved).to.equal(true)

            dynamicStoreClient:destroy()
        end)
    end)
    
    describe("DynamicStoreClient:dispatch", function()
        it("should dispatch the reducer on the key", function()
            local dynamicStoreClient = DynamicStoreClient.new()

            dynamicStoreClient:dispatch("a", "setValue", 1)

            expect(dynamicStoreClient:getValue("a")).to.equal(1)

            dynamicStoreClient:destroy()
        end)

        it("should fire the reduced signal with the key, reducer, and parameters", function()
            local dynamicStoreClient = DynamicStoreClient.new()
            local key, reducer, value

            dynamicStoreClient.reduced:connect(function(...)
                key, reducer, value = ...
            end)

            dynamicStoreClient:dispatch("a", "setValue", 1)

            expect(key).to.equal("a")
            expect(reducer).to.equal("setValue")
            expect(value).to.equal(1)

            dynamicStoreClient:destroy()
        end)

        it("should fire the changed signal with the key, new state, and old state", function()
            local dynamicStoreClient = DynamicStoreClient.new()
            local key, new, old

            dynamicStoreClient.changed:connect(function(...)
                key, new, old = ...
            end)

            dynamicStoreClient:dispatch("a", "setValue", 1)

            expect(key).to.equal("a")
            expect(new.a).to.equal(1)
            expect(old.a).to.equal(nil)

            dynamicStoreClient:destroy()
        end)
    end)

    describe("DynamicStoreClient:setReducers", function()
        it("should set the reducers", function()
            local dynamicStoreClient = DynamicStoreClient.new()
            dynamicStoreClient:dispatch("a", "setValue", 1)

            dynamicStoreClient:setReducers({
                increment = function(old, amount)
                    return old + amount
                end
            })

            dynamicStoreClient:dispatch("a", "increment", 10)

            expect(dynamicStoreClient:getValue("a")).to.equal(11)

            dynamicStoreClient:destroy()
        end)
    end)

    describe("DynamicStoreClient:load", function()
        it("should fire loaded signal with the key that loaded", function()
            local dynamicStoreClient = DynamicStoreClient.new()
            local loaded = false

            dynamicStoreClient.loaded:connect(function(key)
                if key == "a" then
                    loaded = true
                end
            end)

            dynamicStoreClient:load("a", 1)

            expect(loaded).to.equal(true)

            dynamicStoreClient:destroy()
        end)

        it("should set initial value", function()
            local dynamicStoreClient = DynamicStoreClient.new()

            dynamicStoreClient:load("a", 1)

            expect(dynamicStoreClient:getValue("a")).to.equal(1)

            dynamicStoreClient:destroy()
        end)
    end)

    describe("DynamicStoreClient:unload", function()
        it('should fire unloaded signal with the key that unloaded', function()
            local dynamicStoreClient = DynamicStoreClient.new()
            local unloaded = false

            dynamicStoreClient.unloaded:connect(function(key)
                if key == "a" then
                    unloaded = true
                end
            end)

            dynamicStoreClient:unload("a")

            expect(unloaded).to.equal(true)
            dynamicStoreClient:destroy()
        end)

        it("should set value to nil", function()
            local dynamicStoreClient = DynamicStoreClient.new()
            dynamicStoreClient:unload("a")

            expect(dynamicStoreClient:getValue("a")).to.equal(nil)
            
            dynamicStoreClient:destroy()
        end)
    end)

    describe("DynamicStoreClient:destroy", function()
        it("should disconnect any connections", function()
            local dynamicStoreClient = DynamicStoreClient.new()

            local function noop() end

            local connection0 = dynamicStoreClient:getChangedSignal("a"):connect(noop)
            local connection1 = dynamicStoreClient:getReducedSignal("a", "setValue"):connect(noop)
            local connection2 = dynamicStoreClient.changed:connect(noop)
            local connection3 = dynamicStoreClient.reduced:connect(noop)
            local connection4 = dynamicStoreClient.loaded:connect(noop)
            local connection5 = dynamicStoreClient.unloaded:connect(noop)

            dynamicStoreClient:destroy()

            expect(connection0.connected).to.equal(false)
            expect(connection1.connected).to.equal(false)
            expect(connection2.connected).to.equal(false)
            expect(connection3.connected).to.equal(false)
            expect(connection4.connected).to.equal(false)
            expect(connection5.connected).to.equal(false)
        end)

        it("should set destroyed field to true", function()
            local dynamicStoreClient = DynamicStoreClient.new()

            dynamicStoreClient:destroy()

            expect(dynamicStoreClient.destroyed).to.equal(true)
        end)
    end)
end