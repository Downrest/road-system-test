local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PointVector2Data = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.PointVector2Data)
local RoadConfigData = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.RoadConfigData)
local CreateVariantEnums = require(ReplicatedStorage.RoadBuilder.RoadBuilderEnums.CreateVariantEnums)
local RoadTypeEnums = require(ReplicatedStorage.RoadBuilder.RoadBuilderEnums.RoadTypeEnums)

export type CreateRoadRequestConfig = {
    roadType: RoadTypeEnums.RoadTypeEnums;
    createVariant: CreateVariantEnums.CreateVariantEnums;
    overrideRoadConfig: RoadConfigData.OverrideRoadConfigs;
    
    fromPositionVector2Data: PointVector2Data.PointVector2Data;
    toPositionVector2Data: PointVector2Data.PointVector2Data?;
}

return function(
    roadType: RoadTypeEnums.RoadTypeEnums,
    createVariant: CreateVariantEnums.CreateVariantEnums,
    overrideRoadConfig: RoadConfigData.OverrideRoadConfigs,

    fromPositionVector2Data: PointVector2Data.PointVector2Data,
    toPositionVector2Data: PointVector2Data.PointVector2Data?
): CreateRoadRequestConfig
    
    return {
        roadType = roadType;
        createVariant = createVariant;
        overrideRoadConfig = overrideRoadConfig;
        
        fromPositionVector2Data = fromPositionVector2Data;
        toPositionVector2Data = toPositionVector2Data;
    }
end
