local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local TweenService = game:GetService("TweenService")

local PropertiesUtils = require(ReplicatedStorage.SharedUtils.PropertiesUtils)
local TaskbarAnimData = require(StarterPlayer.StarterPlayerScripts.Gui.GuiAnimData.TaskbarAnimData)
local GuiEnums = require(StarterPlayer.StarterPlayerScripts.Gui.GuiEnums)
local GuiGetter = require(StarterPlayer.StarterPlayerScripts.Gui.GuiGetter)
local FocusSignals = require(StarterPlayer.StarterPlayerScripts.Gui.GuiSignals.FocusSignals)

local taskbarGui = GuiGetter.TaskbarGui.gui
local taskbarGuiFrame = GuiGetter.TaskbarGui.guiFrame
local buildButton = GuiGetter.TaskbarGui.buildButton

--// CONFIGURATION

local TASKBAR_GUI_ANIM_DATA = TaskbarAnimData.taskbarGuiFrame

local function init()
    PropertiesUtils.ApplyProperties(taskbarGuiFrame, TASKBAR_GUI_ANIM_DATA.initProperties)
end

init()

FocusSignals.MainInterface.OnFocus(taskbarGui, function()
	warn("taskbar focused")
    TweenService:Create(
        taskbarGuiFrame, 
        TASKBAR_GUI_ANIM_DATA.focusedTweenData.tweenInfo, 
        TASKBAR_GUI_ANIM_DATA.focusedTweenData.tweenProperties
    ):Play()
end)

FocusSignals.MainInterface.OnDefocus(taskbarGui, function()
	warn("taskbar defocused")
    TweenService:Create(
        taskbarGuiFrame, 
        TASKBAR_GUI_ANIM_DATA.defocusedTweenData.tweenInfo, 
        TASKBAR_GUI_ANIM_DATA.defocusedTweenData.tweenProperties
    ):Play()
end)

buildButton.MouseButton1Down:Connect(function()
    FocusSignals.MainInterface.FocusGuis(GuiGetter.BuildGui.gui).DefocusAllGuisExcept()
end)
