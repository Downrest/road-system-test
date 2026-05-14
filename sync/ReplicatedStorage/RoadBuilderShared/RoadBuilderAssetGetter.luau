local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RoadBuilderEnums = require(ReplicatedStorage.RoadBuilderShared.RoadBuilderEnums)
local AssetGetter = {}

local roadsFolder = script.Roads

local enumToRoad = {
	[RoadBuilderEnums.RoadType.Gravel] = roadsFolder.GravelRoad;
	[RoadBuilderEnums.RoadType.Mud] = roadsFolder.MudRoad;
}
local enumToRoadPoint = {
	[RoadBuilderEnums.RoadType.Gravel] = roadsFolder.GravelRoadPoint;
	[RoadBuilderEnums.RoadType.Mud] = roadsFolder.MudRoadPoint;
}

function AssetGetter.GetRoadFromType(roadType: RoadBuilderEnums.RoadType): BasePart
	return enumToRoad[roadType] or error(`RoadBuilderAssetGetter: Road type "{roadType}" is not a valid road`)
end

function AssetGetter.GetRoadPointFromType(roadType: RoadBuilderEnums.RoadType): BasePart
	return enumToRoadPoint[roadType] or error(`RoadBuilderAssetGetter: Road type "{roadType}" is not a valid road point`)
end

return AssetGetter
