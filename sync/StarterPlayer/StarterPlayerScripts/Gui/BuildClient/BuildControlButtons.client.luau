local StarterPlayer = game:GetService("StarterPlayer")

local GuiGetter = require(StarterPlayer.StarterPlayerScripts.Gui.GuiGetter)
local FocusSignals = require(StarterPlayer.StarterPlayerScripts.Gui.GuiSignals.FocusSignals)

local buildControlButtons = GuiGetter.BuildGui.buildControlsButtons
local backButton = buildControlButtons.BackButton
local exitButton = buildControlButtons.ExitButton
local buildMenu = GuiGetter.BuildGui.buildMenu
local roadSelection = GuiGetter.BuildGui.roadSelection

local taskbarGui = GuiGetter.TaskbarGui.gui

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
