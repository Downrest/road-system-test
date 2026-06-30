local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DefaultCreateType = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.CreatePropertyWrappers.DefaultCreateType)
local VisualizeCreateType = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.CreatePropertyWrappers.VisualizeCreateType)
local OverrideRoadConfig = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.CreateRoadWrappers.OverrideRoadConfig)
local RoadTypeEnums = require(ReplicatedStorage.RoadBuilder.RoadBuilderEnums.RoadTypeEnums)

export type RoadConfigData = {
	roadType: RoadTypeEnums.RoadTypeEnums; 
	createType: CreateTypes;
    overrideRoadConfig: OverrideRoadConfig.OverrideRoadConfig?;
}
export type CreateTypes = DefaultCreateType.DefaultCreateType
    | VisualizeCreateType.VisualizeCreateType

return function(
    roadType: RoadTypeEnums.RoadTypeEnums, 
	createType: CreateTypes,
    overrideRoadConfig: OverrideRoadConfig.OverrideRoadConfig?
): RoadConfigData
    return {
        roadType = roadType;
        createType = createType;
        overrideRoadConfig = overrideRoadConfig;
    }
end
