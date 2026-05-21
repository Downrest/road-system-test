local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RoadTypeEnums = require(ReplicatedStorage.RoadBuilder.RoadBuilderEnums.RoadTypeEnums)

local AssetGetter = {}

local roadsFolder = script.Roads
local gravelFolder = roadsFolder.Gravel
local mudFolder = roadsFolder.Mud

local guisFolder = script.Guis
local selectionGui = guisFolder.SelectionGui

local highlightsFolder = script.Highlights
local visualizeRoadHighlight = highlightsFolder.VisualizeRoadHighlight
local visualizeRoadPointHighlight = highlightsFolder.VisualizeRoadPointHighlight

AssetGetter.roadAssets = {
	[RoadTypeEnums.Gravel] = {
		road = gravelFolder.GravelRoad;
		roadPoint = gravelFolder.GravelRoadPoint;
	};
	[RoadTypeEnums.Mud] = {
		road = mudFolder.MudRoad;
		roadPoint = mudFolder.MudRoadPoint;
	}
}

AssetGetter.guis = {
	SelectionGui = selectionGui;
}

AssetGetter.highlights = {
	VisualizeRoadHighlight = visualizeRoadHighlight;
	VisualizeRoadPointHighlight = visualizeRoadPointHighlight;
}

return AssetGetter
