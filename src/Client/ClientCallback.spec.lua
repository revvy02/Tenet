return function()
    local MockNetwork = require(script.Parent.Parent.Parent.MockNetwork)

    local ClientCallback = require(script.Parent.ClientCallback)
    local ServerCallback = require(script.Parent.Parent.Server.ServerCallback)

    describe("ClientCallback.new", function()
        it("should create a new ClientCallback", function()
            local remoteFunction = MockNetwork.MockRemoteFunction.new()

            local clientCallback = ClientCallback.new({
                remoteFunction = remoteFunction,
            })
            
            expect(clientCallback).to.be.ok()
            expect(clientCallback.is(clientCallback)).to.equal(true)

            remoteFunction:destroy()
            clientCallback:destroy()
        end)
    end)

    describe("ClientCallback.is", function()
        it("should return true if the passed object is a ClientCallback", function()
            local remoteFunction = MockNetwork.MockRemoteFunction.new()

            local clientCallback = ClientCallback.new({
                remoteFunction = remoteFunction,
            })

            expect(ClientCallback.is(clientCallback)).to.equal(true)

            remoteFunction:destroy()
            clientCallback:destroy()
        end)

        it("should return false if the passed object is not a ClientCallback", function()
            expect(ClientCallback.is(false)).to.equal(false)
            expect(ClientCallback.is(true)).to.equal(false)
            expect(ClientCallback.is({})).to.equal(false)
        end)
    end)



    describe("ClientCallback:setClientCallback", function()
        it("should resolve any queued requests", function()
            local remoteFunction = MockNetwork.MockRemoteFunction.new()
            local count = 0

            local clientCallback = ClientCallback.new({
                remoteFunction = remoteFunction,
            })
            
            task.spawn(function()
                count += remoteFunction:InvokeClient(1)
            end)

            task.spawn(function()
                count += remoteFunction:InvokeClient(2)
            end)

            clientCallback:setClientCallback(function(num)
                return num * 2
            end)

            expect(count).to.equal(6)

            remoteFunction:destroy()
            clientCallback:destroy()
        end)
    end)

    describe("ClientCallback:flushClient", function()
        it("should ignore any queued requests when the callback is set", function()
            local remoteFunction = MockNetwork.MockRemoteFunction.new()
            local ran0, ran1 = false, false

            local clientCallback = ClientCallback.new({
                remoteFunction = remoteFunction,
            })
            
            task.spawn(function()
                ran0 = remoteFunction:InvokeClient()
            end)

            task.spawn(function()
                ran1 = remoteFunction:InvokeClient()
            end)

            clientCallback:flushClient()

            clientCallback:setClientCallback(function(num)
                return true
            end)

            expect(ran0).to.equal(false)
            expect(ran1).to.equal(false)

            remoteFunction:destroy()
            clientCallback:destroy()
        end)
    end)




    describe("ClientCallback:callServerAsync", function()
        it("should return the server response", function()
            local remoteFunction = MockNetwork.MockRemoteFunction.new()

            remoteFunction.OnServerInvoke = function()
                return true
            end

            local clientCallback = ClientCallback.new({
                remoteFunction = remoteFunction,
            })
            
            expect(clientCallback:callServerAsync():await()).to.equal(true)

            remoteFunction:destroy()
            clientCallback:destroy()
        end)

        it("should queue request if the server callback isn't set and resolve once it is", function()
            local remoteFunction = MockNetwork.MockRemoteFunction.new()
            local response = false

            local clientCallback = ClientCallback.new({
                remoteFunction = remoteFunction,
            })

            task.spawn(function()
                response = clientCallback:callServerAsync():await()
            end)

            expect(response).to.equal(false)

            remoteFunction.OnServerInvoke = function()
                return true
            end

            expect(response).to.equal(true)

            remoteFunction:destroy()
            clientCallback:destroy()
        end)
    end)







    describe("ClientCallback:destroy", function()
        it("should set destroyed field to true", function()
            local remoteFunction = MockNetwork.MockRemoteFunction.new()

            local clientCallback = ClientCallback.new({
                remoteFunction = remoteFunction,
            })
            
            remoteFunction:destroy()
            clientCallback:destroy()

            expect(clientCallback.destroyed).to.equal(true)
        end)
    end)
end