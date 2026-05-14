local StarterPlayer = game:GetService("StarterPlayer")

local GuiEnums = require(StarterPlayer.StarterPlayerScripts.ClientGui.GuiEnums)
local GuiGetter = require(StarterPlayer.StarterPlayerScripts.ClientGui.GuiGetter)
local GuiSignals = require(StarterPlayer.StarterPlayerScripts.ClientGui.GuiSignals)

local buildGui = GuiGetter.BuildGui

local defocusGuiSignal = GuiSignals.DefocusGui

GuiSignals.OnDefocus(buildGui, function()
    taskbarGui.Enabled = false
end)