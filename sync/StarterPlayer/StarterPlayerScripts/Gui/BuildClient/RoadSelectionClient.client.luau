local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local TweenService = game:GetService("TweenService")

local BuildAnimData = require(StarterPlayer.StarterPlayerScripts.Gui.GuiAnimData.BuildAnimData)
local RoadBuilderPresets = require(ReplicatedStorage.RoadBuilder.RoadBuilderPresets)
local PropertiesUtils = require(ReplicatedStorage.SharedUtils.PropertiesUtils)
local FocusSignals = require(StarterPlayer.StarterPlayerScripts.Gui.GuiSignals.FocusSignals)
local GuiAssetGetter = require(StarterPlayer.StarterPlayerScripts.Gui.GuiUtils.GuiAssetGetter)
local RoadBuilderState = require(StarterPlayer.StarterPlayerScripts.RoadBuilderClient.RoadBuilderState)

local roadSelection = GuiAssetGetter.BuildGui.roadSelection
local roadTemplates = roadSelection.Templates
local ROAD_BUTTON = roadTemplates.RoadButton
local buildMenu = GuiAssetGetter.BuildGui.buildMenu

local ROAD_SELECTION_ANIM_DATA = BuildAnimData.roadSelection

type RoadButtonInstances = {
    roadButton: GuiButton;
    roadName: TextLabel;
    roadIcon: ImageLabel;
    lockedDim: GuiBase;
}

local function roadButtonUpdate(roadButtonInstances: RoadButtonInstances, roadPreset)
    local roadButton = roadButtonInstances.roadButton
    local roadName = roadButtonInstances.roadName
    local roadIcon = roadButtonInstances.roadIcon
    local lockedDim = roadButtonInstances.lockedDim

    roadButton.Visible = true
    roadButton.Name = `{roadPreset.Name}Button`
    roadName.Text = roadPreset.Name
    roadIcon.Image = roadPreset.Gui.IconImageId
end

local function roadButtonTrigger(roadButtonInstances: RoadButtonInstances, roadPreset)
    RoadBuilderState.CurrentRoadType(roadPreset.RoadType)
    FocusSignals.BuildInterface.FocusGuis(buildMenu).DefocusAllGuisExcept()
end

local function init()
	for _, roadPreset in RoadBuilderPresets.RoadTypeData do
        local roadButtonClone = ROAD_BUTTON:Clone()
        local roadButtonInstances = {
            roadButton = roadButtonClone;
            roadName = roadButtonClone.RoadName;
            roadIcon = roadButtonClone.RoadIcon;
            lockedDim = roadButtonClone.LockedDim;
        }

        roadButtonUpdate(roadButtonInstances, roadPreset)
        roadButtonClone.Parent = roadSelection.RoadList

        roadButtonClone.MouseButton1Click:Connect(function()
            roadButtonTrigger(roadButtonInstances, roadPreset)
        end)
	end

    PropertiesUtils.ApplyProperties(roadSelection, ROAD_SELECTION_ANIM_DATA.initProperties)
end

init()

FocusSignals.BuildInterface.OnFocus(roadSelection, function()
    warn("roadselection focused")
    TweenService:Create(
        roadSelection, 
        ROAD_SELECTION_ANIM_DATA.focusedTweenData.tweenInfo, 
        ROAD_SELECTION_ANIM_DATA.focusedTweenData.tweenProperties
    ):Play()
end)

FocusSignals.BuildInterface.OnDefocus(roadSelection, function()
    warn("roadselection defocused")
    
    TweenService:Create(
        roadSelection, 
        ROAD_SELECTION_ANIM_DATA.defocusedTweenData.tweenInfo, 
        ROAD_SELECTION_ANIM_DATA.defocusedTweenData.tweenProperties
    ):Play()
end)
