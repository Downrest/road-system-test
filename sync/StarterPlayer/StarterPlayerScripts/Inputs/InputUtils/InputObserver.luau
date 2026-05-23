local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.SharedPackages.Signal)

local Observer = {}

local DEFAULT_SHOULD_CREATE_BUTTON = false

--[[
    Wrapper for `ContextActionService:BindAction()`, returns a `onPressSignal` and `onReleaseSignal` for any script to listen into.
]]
function Observer.Generate(
    bindName: string,
    bindInputs: {Enum.KeyCode | Enum.UserInputType},
    shouldCreateButton: boolean?
): Signal.Signal<(input: Enum.KeyCode | Enum.UserInputType) -> ()>
    local onPressSignal = Signal.new()
    local onReleaseSignal = Signal.new()
    shouldCreateButton = shouldCreateButton or DEFAULT_SHOULD_CREATE_BUTTON

    ContextActionService:BindAction(
        bindName, 
        function(_, inputState, inputObject)
            if inputState == Enum.UserInputState.Begin then
                onPressSignal:Fire(inputObject.KeyCode or inputObject.UserInputType)
            elseif inputState == Enum.UserInputState.End then
                onReleaseSignal:Fire(inputObject.KeyCode or inputObject.UserInputType)
            end
        end,
        shouldCreateButton,
        table.unpack(bindInputs)
    )

    return onPressSignal, onReleaseSignal
end

return Observer
