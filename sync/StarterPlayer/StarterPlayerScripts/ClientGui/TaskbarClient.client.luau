local StarterPlayer = game:GetService("StarterPlayer")

local GuiEnums = require(StarterPlayer.StarterPlayerScripts.ClientGui.GuiEnums)
local GuiGetter = require(StarterPlayer.StarterPlayerScripts.ClientGui.GuiGetter)
local GuiSignals = require(StarterPlayer.StarterPlayerScripts.ClientGui.GuiSignals)

local taskbarGui = GuiGetter.TaskbarGui
local frame = taskbarGui.Frame
local buildButton = frame.BuildButton

local defocusGuiSignal = GuiSignals.DefocusGui

GuiSignals.OnDefocus(taskbarGui, function()
    taskbarGui.Enabled = false
end)

buildButton.MouseButton1Down:Connect(function()
    GuiSignals.FocusGuis(GuiEnums.focusLists.MainInterface)
end)
