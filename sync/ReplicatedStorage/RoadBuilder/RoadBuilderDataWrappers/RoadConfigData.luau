local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DefaultCreateType = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.CreateTypeWrappers.DefaultCreateType)
local VisualizeCreateType = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.CreateTypeWrappers.VisualizeCreateType)
local CreateTypeEnums = require(ReplicatedStorage.RoadBuilder.RoadBuilderEnums.CreateTypeEnums)
local RoadTypeEnums = require(ReplicatedStorage.RoadBuilder.RoadBuilderEnums.RoadTypeEnums)

export type RoadConfigData = {
	roadType: RoadTypeEnums.RoadTypeEnums; 
	createType: CreateTypes;
	roadParent: Instance;
    overrideDependentRoads: boolean;
}

export type CreateTypes = DefaultCreateType.DefaultCreateType
    | VisualizeCreateType.VisualizeCreateType

return function(
    roadType: RoadTypeEnums.RoadTypeEnums, 
	createType: CreateTypes,
	roadParent: Instance,
    overrideDependentRoads: boolean?
): RoadConfigData
    assert(roadType, "No roadType: string")
	assert(createType, "No createType: string")
	assert(roadParent, "No roadParent: Instance")

    return {
        roadType = roadType;
        createType = createType;
        roadParent = roadParent;
        overrideDependentRoads = overrideDependentRoads or false;
    }
end
