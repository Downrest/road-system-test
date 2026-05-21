local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local TweenService = game:GetService("TweenService")

local PropertiesUtils = require(ReplicatedStorage.SharedUtils.PropertiesUtils)
local AnimData = require(StarterPlayer.StarterPlayerScripts.Gui.GuiDataWrappers.AnimDataWrappers.AnimData)

local Animations = {}

function Animations.Init(
    instance: GuiObject,
    animData: AnimData.AnimData
)
    PropertiesUtils.ApplyProperties(instance, animData.initProperties)
end

function Animations.EnterTween(
    instance: GuiObject,
    animData: AnimData.AnimData
)
    TweenService:Create(
        instance, 
        animData.focusedTweenData.tweenInfo, 
        animData.focusedTweenData.tweenProperties
    ):Play()
end

function Animations.ExitTween(
    instance: GuiObject,
    animData: AnimData.AnimData
)
    TweenService:Create(
        instance, 
        animData.defocusedTweenData.tweenInfo, 
        animData.defocusedTweenData.tweenProperties
    ):Play()
end

return Animations
