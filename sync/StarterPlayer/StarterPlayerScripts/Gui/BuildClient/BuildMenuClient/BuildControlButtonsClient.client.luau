local StarterPlayer = game:GetService("StarterPlayer")

local FocusSignals = require(StarterPlayer.StarterPlayerScripts.Gui.GuiSignals.FocusSignals)
local GuiAssetGetter = require(StarterPlayer.StarterPlayerScripts.Gui.GuiUtils.GuiAssetGetter)

local buildControlButtons = GuiAssetGetter.BuildGui.buildControlsButtons
local backButton = buildControlButtons.BackButton
local exitButton = buildControlButtons.ExitButton
local buildMenu = GuiAssetGetter.BuildGui.buildMenu
local roadSelection = GuiAssetGetter.BuildGui.roadSelection

local taskbarGui = GuiAssetGetter.TaskbarGui.gui

local function init()
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
    buildControlButtons.Visible = true
end)

FocusSignals.BuildInterface.OnDefocus(buildMenu, function()
    warn("roadselection defocused")
    buildControlButtons.Visible = false
end)
