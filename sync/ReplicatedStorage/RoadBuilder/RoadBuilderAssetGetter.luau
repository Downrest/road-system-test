local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RoadBuilderEnums = require(ReplicatedStorage.RoadBuilder.RoadBuilderEnums)
local AssetGetter = {}

local gravelFolder = script.Gravel
local mudFolder = script.Mud

local enumToRoad = {
	[RoadBuilderEnums.RoadType.Gravel] = gravelFolder.GravelRoad;
	[RoadBuilderEnums.RoadType.Mud] = mudFolder.MudRoad;
}
local enumToRoadPoint = {
	[RoadBuilderEnums.RoadType.Gravel] = gravelFolder.GravelRoadPoint;
	[RoadBuilderEnums.RoadType.Mud] = mudFolder.MudRoadPoint;
}

function AssetGetter.GetRoadFromType(roadType: RoadBuilderEnums.RoadType): BasePart
	return enumToRoad[roadType] or error(`RoadBuilderRoadBuilderAssetGetter: Road type "{roadType}" is not a valid road`)
end

function AssetGetter.GetRoadPointFromType(roadType: RoadBuilderEnums.RoadType): BasePart
	return enumToRoadPoint[roadType] or error(`RoadBuilderRoadBuilderAssetGetter: Road type "{roadType}" is not a valid road point`)
end

return AssetGetter
