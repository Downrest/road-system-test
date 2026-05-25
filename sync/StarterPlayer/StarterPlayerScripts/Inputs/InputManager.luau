local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local Signal = require(ReplicatedStorage.SharedPackages.Signal)
local InputBindEnums = require(StarterPlayer.StarterPlayerScripts.Inputs.InputEnums.InputBindEnums)
local InputSettings = require(StarterPlayer.StarterPlayerScripts.Inputs.InputSettings)

local Manager = {}

--// CONFIGURATION

local SHOULD_CREATE_BUTTON_ON_INPUT_SIGNAL = false

type InputSignal = Signal.Signal<(input: Enum.KeyCode | Enum.UserInputType) -> ()>

local function generateInputSignal(
	bindName: string,
	bindInputs: {Enum.KeyCode | Enum.UserInputType},
	shouldCreateButton: boolean?
): (InputSignal, InputSignal)
	local onPressSignal = Signal.new()
	local onReleaseSignal = Signal.new()
	shouldCreateButton = shouldCreateButton or SHOULD_CREATE_BUTTON_ON_INPUT_SIGNAL

	ContextActionService:BindActionAtPriority(
		bindName, 
		function(_, inputState, inputObject)
			warn(inputState)
			if inputState == Enum.UserInputState.Begin then
				onPressSignal:Fire(inputObject.KeyCode or inputObject.UserInputType)
			elseif inputState == Enum.UserInputState.End then
				onReleaseSignal:Fire(inputObject.KeyCode or inputObject.UserInputType)
			end
		end,
		shouldCreateButton,
		Enum.ContextActionPriority.High.Value,
		table.unpack(bindInputs)
	)

	return onPressSignal, onReleaseSignal
end

Manager.OnPress, Manager.UnPress = generateInputSignal(
    InputBindEnums.Press, 
    InputSettings.Keys.ON_PRESS
)

return Manager
