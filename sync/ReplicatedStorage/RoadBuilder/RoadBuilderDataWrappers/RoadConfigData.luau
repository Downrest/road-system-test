local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DefaultCreateType = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.CreatePropertyWrappers.DefaultCreateType)
local VisualizeCreateType = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.CreatePropertyWrappers.VisualizeCreateType)
local ClearPreviousRoad = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.OverrideRoadWrappers.ClearPreviousRoad)
local SetPointCacheType = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.OverrideRoadWrappers.SetPointCacheType)
local RoadTypeEnums = require(ReplicatedStorage.RoadBuilder.RoadBuilderEnums.RoadTypeEnums)

export type OverrideRoadConfigs = ClearPreviousRoad.ClearPreviousRoad | SetPointCacheType.SetPointCacheType
export type RoadConfigData = {
	roadType: RoadTypeEnums.RoadTypeEnums; 
	createType: CreateTypes;
    overrideRoadConfig: OverrideRoadConfigs?;
}
export type CreateTypes = DefaultCreateType.DefaultCreateType
    | VisualizeCreateType.VisualizeCreateType

return function(
    roadType: RoadTypeEnums.RoadTypeEnums, 
	createType: CreateTypes,
    overrideRoadConfig: OverrideRoadConfigs?
): RoadConfigData
    return {
        roadType = roadType;
        createType = createType;
        overrideRoadConfig = overrideRoadConfig;
    }
end
