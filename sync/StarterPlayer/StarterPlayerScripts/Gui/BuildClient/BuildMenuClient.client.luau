local StarterPlayer = game:GetService("StarterPlayer")

local GuiAssetGetter = require(StarterPlayer.StarterPlayerScripts.Gui.GuiUtils.GuiAssetGetter)
local FocusSignals = require(StarterPlayer.StarterPlayerScripts.Gui.GuiSignals.FocusSignals)
local RoadBuilderState = require(StarterPlayer.StarterPlayerScripts.RoadBuilderClient.RoadBuilderState)

local buildMenu = GuiAssetGetter.BuildGui.buildMenu

FocusSignals.BuildInterface.OnFocus(buildMenu, function()
    warn("roadselection focused")
    RoadBuilderState.IsInBuildMenu(true)
    
    buildMenu.Visible = true
end)

FocusSignals.BuildInterface.OnDefocus(buildMenu, function()
	warn("roadselection defocused")
	RoadBuilderState.IsInBuildMenu(false)
	
    buildMenu.Visible = false
end)
