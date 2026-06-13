local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CreateTypeEnums = require(ReplicatedStorage.RoadBuilder.RoadBuilderEnums.CreateTypeEnums)
local RoadTypeEnums = require(ReplicatedStorage.RoadBuilder.RoadBuilderEnums.RoadTypeEnums)

export type RoadConfigData = {
	roadType: RoadTypeEnums.RoadTypeEnums; 
	createType: CreateTypeEnums.CreateTypeEnums;
	roadParent: Instance;
    overrideDependentRoads: boolean;
}

return function(
    roadType: RoadTypeEnums.RoadTypeEnums, 
	createType: CreateTypeEnums.CreateTypeEnums,
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
