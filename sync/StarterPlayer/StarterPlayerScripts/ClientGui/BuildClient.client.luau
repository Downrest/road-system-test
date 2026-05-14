local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local RoadBuilderEnums = require(ReplicatedStorage.RoadBuilder.RoadBuilderEnums)
local RoadBuilderPresets = require(ReplicatedStorage.RoadBuilder.RoadBuilderPresets)
local GuiEnums = require(StarterPlayer.StarterPlayerScripts.ClientGui.GuiEnums)
local GuiGetter = require(StarterPlayer.StarterPlayerScripts.ClientGui.GuiGetter)
local FocusSignals = require(StarterPlayer.StarterPlayerScripts.ClientGui.GuiSignals.FocusSignals)
local RoadBuilderState = require(StarterPlayer.StarterPlayerScripts.RoadBuilderClient.RoadBuilderState)

local buildGui = GuiGetter.BuildGui
local roadSelection = buildGui.RoadSelection
local roadTemplates = roadSelection.Templates
local ROAD_BUTTON = roadTemplates.RoadButton

local defocusGuiSignal = FocusSignals.DefocusGui

type RoadButtonInstances = {
    roadButton: GuiButton;
    roadName: TextLabel;
    roadIcon: ImageLabel;
    lockedDim: GuiBase;
}

local function roadButtonUpdate(roadButtonInstances: RoadButtonInstances, roadData: RoadBuilderEnums.RoadData)
    local roadButton = roadButtonInstances.roadButton
    local roadName = roadButtonInstances.roadName
    local roadIcon = roadButtonInstances.roadIcon
    local lockedDim = roadButtonInstances.lockedDim

    roadButton.Visible = true
    roadButton.Name = `{roadData.Name}Button`
    roadName.Name = roadData.Name
    roadIcon.Image = roadData.Gui.IconImageId
end

local function roadButtonTrigger(roadButtonInstances: RoadButtonInstances, roadData: RoadBuilderEnums.RoadData)
    RoadBuilderState.CurrentRoadType = roadData.RoadType
end

local function init()
	for _, roadData in RoadBuilderPresets.RoadTypeData do
        local roadButtonClone = ROAD_BUTTON:Clone()
        local roadButtonInstances = {
            roadButton = roadButtonClone;
            roadName = roadButtonClone.RoadName;
            roadIcon = roadButtonClone.RoadIcon;
            lockedDim = roadButtonClone.LockedDim;
        }

        roadButtonUpdate(roadButtonInstances, roadData)
        roadButtonClone.Parent = roadSelection

        roadButtonClone.MouseButton1Click:Connect(function()
            roadButtonTrigger(roadButtonInstances, roadData)
        end)
	end
end

init()

FocusSignals.OnFocus(buildGui, function()
    buildGui.Enabled = true
end)

FocusSignals.OnDefocus(buildGui, function()
    buildGui.Enabled = false
end)