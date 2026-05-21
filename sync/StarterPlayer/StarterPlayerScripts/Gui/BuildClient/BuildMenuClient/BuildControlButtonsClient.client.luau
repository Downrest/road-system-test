local StarterPlayer = game:GetService("StarterPlayer")

local BuildAnimData = require(StarterPlayer.StarterPlayerScripts.Gui.GuiAnimData.BuildAnimData)
local FocusSignals = require(StarterPlayer.StarterPlayerScripts.Gui.GuiSignals.FocusSignals)
local GuiAnimations = require(StarterPlayer.StarterPlayerScripts.Gui.GuiUtils.GuiAnimations)
local GuiAssetGetter = require(StarterPlayer.StarterPlayerScripts.Gui.GuiAssetGetter)

local buildControlButtons = GuiAssetGetter.BuildGui.buildControlsButtons
local backButton = buildControlButtons.BackButton
local exitButton = buildControlButtons.ExitButton
local buildMenu = GuiAssetGetter.BuildGui.buildMenu
local roadSelection = GuiAssetGetter.BuildGui.roadSelection
local taskbarGui = GuiAssetGetter.TaskbarGui.gui

local BUILD_CONTROL_BUTTONS_ANIM_DATA = BuildAnimData.buildControlButtons

local function init()
    GuiAnimations.Init(buildControlButtons, BUILD_CONTROL_BUTTONS_ANIM_DATA)

    backButton.MouseButton1Click:Connect(function()
        FocusSignals.BuildInterface:FocusGuis(roadSelection).DefocusAllGuisExcept()
    end)
    exitButton.MouseButton1Click:Connect(function()
        FocusSignals.MainInterface:FocusGuis(taskbarGui).DefocusAllGuisExcept()
    end)
end

init()

FocusSignals.BuildInterface.OnFocus(buildMenu, function()
    warn("roadselection focused")
    GuiAnimations.EnterTween(buildControlButtons, BUILD_CONTROL_BUTTONS_ANIM_DATA)
end)

FocusSignals.BuildInterface.OnDefocus(buildMenu, function()
    warn("roadselection defocused")
    GuiAnimations.ExitTween(buildControlButtons, BUILD_CONTROL_BUTTONS_ANIM_DATA)
end)
