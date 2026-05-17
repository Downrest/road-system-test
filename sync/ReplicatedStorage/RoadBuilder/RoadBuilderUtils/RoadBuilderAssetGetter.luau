local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RoadTypeEnums = require(ReplicatedStorage.RoadBuilder.RoadBuilderEnums.RoadTypeEnums)

local AssetGetter = {}

local roadsFolder = script.Roads
local gravelFolder = roadsFolder.Gravel
local mudFolder = roadsFolder.Mud

local guis = script.Guis
local selectionGui = guis.SelectionGui

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

return AssetGetter
