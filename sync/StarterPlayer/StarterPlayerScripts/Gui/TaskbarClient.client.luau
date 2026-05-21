local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local TweenService = game:GetService("TweenService")

local PropertiesUtils = require(ReplicatedStorage.SharedUtils.PropertiesUtils)
local TaskbarAnimData = require(StarterPlayer.StarterPlayerScripts.Gui.GuiAnimData.TaskbarAnimData)
local GuiAssetGetter = require(StarterPlayer.StarterPlayerScripts.Gui.GuiUtils.GuiAssetGetter)
local FocusSignals = require(StarterPlayer.StarterPlayerScripts.Gui.GuiSignals.FocusSignals)
local GuiAnimations = require(StarterPlayer.StarterPlayerScripts.Gui.GuiUtils.GuiAnimations)

local taskbarGui = GuiAssetGetter.TaskbarGui.gui
local taskbarGuiFrame = GuiAssetGetter.TaskbarGui.guiFrame
local buildButton = GuiAssetGetter.TaskbarGui.buildButton

--// CONFIGURATION

local TASKBAR_GUI_ANIM_DATA = TaskbarAnimData.taskbarGuiFrame

local function init()
    GuiAnimations.Init(taskbarGuiFrame, TASKBAR_GUI_ANIM_DATA)

    buildButton.MouseButton1Down:Connect(function()
        FocusSignals.MainInterface.FocusGuis(GuiAssetGetter.BuildGui.gui).DefocusAllGuisExcept()
    end)
end

init()

FocusSignals.MainInterface.OnFocus(taskbarGui, function()
	warn("taskbar focused")
    GuiAnimations.EnterTween(taskbarGuiFrame, TASKBAR_GUI_ANIM_DATA)
end)

FocusSignals.MainInterface.OnDefocus(taskbarGui, function()
	warn("taskbar defocused")
    GuiAnimations.ExitTween(taskbarGuiFrame, TASKBAR_GUI_ANIM_DATA)
end)