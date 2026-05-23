local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local InputBindEnums = require(StarterPlayer.StarterPlayerScripts.Inputs.InputEnums.InputBindEnums)
local InputSettings = require(StarterPlayer.StarterPlayerScripts.Inputs.InputSettings)
local InputObserver = require(StarterPlayer.StarterPlayerScripts.Inputs.InputUtils.InputObserver)

local Manager = {}

Manager.OnPress, Manager.UnPress = InputObserver.Generate(
    InputBindEnums.Press, 
    InputSettings.Keys.ON_PRESS
)

return Manager
