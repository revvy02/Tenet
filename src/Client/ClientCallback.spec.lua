return function()
    local MockNetwork = require(script.Parent.Parent.Parent.MockNetwork)
    local Promise = require(script.Parent.Parent.Parent.Promise)

    local ClientCallback = require(script.Parent.ClientCallback)
    
    local function createClientCallback()
        local remoteFunction = MockNetwork.MockRemoteFunction.new()

        local clientCallback = ClientCallback.new({
            remoteFunction = remoteFunction,
        })

        return clientCallback, function()
            clientCallback:destroy()
            remoteFunction:destroy()
        end, remoteFunction
    end

    describe("ClientCallback.new", function()
        it("should create a new ClientCallback", function()
            local clientCallback, cleanup = createClientCallback()
            
            expect(clientCallback).to.be.ok()
            expect(ClientCallback.is(clientCallback)).to.equal(true)

            cleanup()
        end)
    end)

    describe("ClientCallback.is", function()
        it("should return true if the passed object is a ClientCallback", function()
            local clientCallback, cleanup = createClientCallback()

            expect(ClientCallback.is(clientCallback)).to.equal(true)

            cleanup()
        end)

        it("should return false if the passed object is not a ClientCallback", function()
            expect(ClientCallback.is(false)).to.equal(false)
            expect(ClientCallback.is(true)).to.equal(false)
            expect(ClientCallback.is({})).to.equal(false)
        end)
    end)



    describe("ClientCallback:setCallback", function()
        it("should resolve any queued requests", function()
            local clientCallback, cleanup, remoteFunction = createClientCallback()
            local count = 0

            task.spawn(function()
                local new = remoteFunction:invokeClient(nil, 1)
                count += new
            end)

            task.spawn(function()
                local new = remoteFunction:invokeClient(nil, 2)
                count += new
            end)

            clientCallback:setCallback(function(num)
                return num * 2
            end)

            expect(count).to.equal(6)

            cleanup()
        end)
    end)

    describe("ClientCallback:flush", function()
        it("should flush any queued requests so they aren't handled when handler is set", function()
            local clientCallback, cleanup, remoteFunction = createClientCallback()
            local ran0, ran1 = false, false
            
            task.spawn(function()
                ran0 = remoteFunction:invokeClient(nil)
            end)

            clientCallback:flush()

            task.spawn(function()
                ran1 = remoteFunction:invokeClient(nil)
            end)

            clientCallback:setCallback(function(num)
                return true
            end)

            expect(ran0).to.equal(false)
            expect(ran1).to.equal(true)

            cleanup()
        end)
    end)




    describe("ClientCallback:callServerAsync", function()
        it("should return a promise that resolves with the server response", function()
            local clientCallback, cleanup, remoteFunction = createClientCallback()

            remoteFunction.OnServerInvoke = function()
                return 1
            end

            local response = clientCallback:callServerAsync()

            expect(Promise.is(response)).to.equal(true)
            expect(select(2, response:await())).to.equal(1)

            cleanup()
        end)

        it("should queue request if the server callback isn't set and resolve once it is", function()
            local clientCallback, cleanup, remoteFunction = createClientCallback()
            local response = false

            task.spawn(function()
                response = select(2, clientCallback:callServerAsync():await())
            end)

            expect(response).to.equal(false)

            remoteFunction.OnServerInvoke = function()
                return true
            end

            expect(response).to.equal(true)

            cleanup()
        end)
    end)







    describe("ClientCallback:destroy", function()
        it("should set destroyed field to true", function()
            local clientCallback, cleanup, remoteFunction = createClientCallback()

            cleanup()

            expect(clientCallback.destroyed).to.equal(true)
        end)
    end)
end