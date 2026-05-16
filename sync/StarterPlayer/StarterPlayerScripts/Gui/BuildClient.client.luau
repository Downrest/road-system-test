local StarterPlayer = game:GetService("StarterPlayer")

local GuiGetter = require(StarterPlayer.StarterPlayerScripts.Gui.GuiGetter)
local FocusSignals = require(StarterPlayer.StarterPlayerScripts.Gui.GuiSignals.FocusSignals)
local RoadBuilderState = require(StarterPlayer.StarterPlayerScripts.RoadBuilderClient.RoadBuilderState)

local buildGui = GuiGetter.BuildGui.gui
local roadSelection = GuiGetter.BuildGui.roadSelection

local defocusGuiSignal = FocusSignals.DefocusGui

FocusSignals.MainInterface.OnFocus(buildGui, function()
    FocusSignals.BuildInterface.FocusGuis(roadSelection).DefocusAllGuisExcept()
end)

FocusSignals.MainInterface.OnDefocus(buildGui, function()
    RoadBuilderState.IsBuilding = false
	FocusSignals.BuildInterface.DefocusAllGuisExcept()
end)