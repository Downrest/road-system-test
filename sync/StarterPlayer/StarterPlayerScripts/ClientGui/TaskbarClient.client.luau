local StarterPlayer = game:GetService("StarterPlayer")

local GuiEnums = require(StarterPlayer.StarterPlayerScripts.ClientGui.GuiEnums)
local GuiGetter = require(StarterPlayer.StarterPlayerScripts.ClientGui.GuiGetter)
local FocusSignals = require(StarterPlayer.StarterPlayerScripts.ClientGui.GuiSignals.FocusSignals)

local taskbarGui = GuiGetter.TaskbarGui
local frame = taskbarGui.Frame
local buildButton = frame.BuildButton

local defocusGuiSignal = FocusSignals.DefocusGui

FocusSignals.OnFocus(taskbarGui, function()
    taskbarGui.Enabled = true
end)

FocusSignals.OnDefocus(taskbarGui, function()
    taskbarGui.Enabled = false
end)

buildButton.MouseButton1Down:Connect(function()
    FocusSignals.FocusGuis(GuiGetter.BuildGui)
end)
