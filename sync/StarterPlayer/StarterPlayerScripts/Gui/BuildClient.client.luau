local StarterPlayer = game:GetService("StarterPlayer")

local FocusSignals = require(StarterPlayer.StarterPlayerScripts.Gui.GuiSignals.FocusSignals)
local GuiAssetGetter = require(StarterPlayer.StarterPlayerScripts.Gui.GuiUtils.GuiAssetGetter)
local RoadBuilderState = require(StarterPlayer.StarterPlayerScripts.RoadBuilderClient.RoadBuilderState)

local buildGui = GuiAssetGetter.BuildGui.gui
local roadSelection = GuiAssetGetter.BuildGui.roadSelection

local defocusGuiSignal = FocusSignals.DefocusGui

FocusSignals.MainInterface.OnFocus(buildGui, function()
    FocusSignals.BuildInterface.FocusGuis(roadSelection).DefocusAllGuisExcept()
end)

FocusSignals.MainInterface.OnDefocus(buildGui, function()
	FocusSignals.BuildInterface.DefocusAllGuisExcept()
end)