local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.SharedPackages.Signal)

local SignalYield = {}

local function cleanupBin(bin: {RBXScriptConnection & thread})
    for _, object in bin do
        local objectType = typeof(object)

        if objectType == "RBXScriptConnection" then
            object:Disconnect()
        elseif objectType == "thread" then
            task.defer(task.cancel, object)
        end
    end
end

function SignalYield.Yield(signals: {RBXScriptSignal}, timeout: number?): any?
    local yieldSignal = Signal.new()
    local bin = {}

    if timeout then
       table.insert(bin,  task.spawn(function()
            task.wait(timeout)
            yieldSignal:Fire()
        end))
    end
    for _, signal in signals do
        table.insert(bin, signal:Once(function(...)
            yieldSignal:Fire(...)
        end))
    end

    local capturedValue = yieldSignal:Wait()
    cleanupBin(bin)
    yieldSignal:Destroy()

    return capturedValue
end

return SignalYield
