local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local InputSettings = require(StarterPlayer.StarterPlayerScripts.Inputs.InputSettings)
local Signal = require(ReplicatedStorage.SharedPackages.Signal)

local Manager = {}

local MANAGER_BIND_NAMES = {
    OnPress = "OnPress";
}

Manager.OnPress = Signal.new()
ContextActionService:BindAction(MANAGER_BIND_NAMES.OnPress, function(_, inputState)
    if inputState == Enum.UserInputState.Begin then
        Manager.OnPress:Fire()
    end
end, false, table.unpack(InputSettings.Keys.ON_PRESS))

return Manager
