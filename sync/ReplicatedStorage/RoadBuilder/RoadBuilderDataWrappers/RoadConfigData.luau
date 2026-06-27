local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DefaultCreateType = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.CreatePropertyWrappers.DefaultCreateType)
local VisualizeCreateType = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.CreatePropertyWrappers.VisualizeCreateType)
local RoadTypeEnums = require(ReplicatedStorage.RoadBuilder.RoadBuilderEnums.RoadTypeEnums)

export type RoadConfigData = {
	roadType: RoadTypeEnums.RoadTypeEnums; 
	createType: CreateTypes;
    overrideDependentRoads: boolean;
}

export type CreateTypes = DefaultCreateType.DefaultCreateType
    | VisualizeCreateType.VisualizeCreateType

return function(
    roadType: RoadTypeEnums.RoadTypeEnums, 
	createType: CreateTypes,
    overrideDependentRoads: boolean?
): RoadConfigData
    return {
        roadType = roadType;
        createType = createType;
        overrideDependentRoads = overrideDependentRoads or false;
    }
end
