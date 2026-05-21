local StarterPlayer = game:GetService("StarterPlayer")

local BuildAnimData = require(StarterPlayer.StarterPlayerScripts.Gui.GuiAnimData.BuildAnimData)
local GuiAssetGetter = require(StarterPlayer.StarterPlayerScripts.Gui.GuiAssetGetter)
local FocusSignals = require(StarterPlayer.StarterPlayerScripts.Gui.GuiSignals.FocusSignals)
local GuiAnimations = require(StarterPlayer.StarterPlayerScripts.Gui.GuiUtils.GuiAnimations)
local RoadBuilderState = require(StarterPlayer.StarterPlayerScripts.RoadBuilderClient.RoadBuilderState)

local buildMenu = GuiAssetGetter.BuildGui.buildMenu

local BUILD_MENU_ANIM_DATA = BuildAnimData.buildMenu

local function init()
    GuiAnimations.Init(buildMenu, BUILD_MENU_ANIM_DATA)
end

init()

FocusSignals.BuildInterface.OnFocus(buildMenu, function()
    warn("roadselection focused")
    RoadBuilderState.IsInBuildMenu(true)
    
    GuiAnimations.EnterTween(buildMenu, BUILD_MENU_ANIM_DATA)
end)

FocusSignals.BuildInterface.OnDefocus(buildMenu, function()
	warn("roadselection defocused")
	RoadBuilderState.IsInBuildMenu(false)
	
    GuiAnimations.ExitTween(buildMenu, BUILD_MENU_ANIM_DATA)
end)
