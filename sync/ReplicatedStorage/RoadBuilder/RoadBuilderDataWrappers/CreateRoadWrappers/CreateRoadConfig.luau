local ReplicatedStorage = game:GetService("ReplicatedStorage")

local OverrideRoadConfig = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.CreateRoadWrappers.OverrideRoadConfig)
local PointVector2Data = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.PointVector2Data)
local CreateVariantEnums = require(ReplicatedStorage.RoadBuilder.RoadBuilderEnums.CreateVariantEnums)
local RoadTypeEnums = require(ReplicatedStorage.RoadBuilder.RoadBuilderEnums.RoadTypeEnums)

export type CreateRoadConfig = {
    roadType: RoadTypeEnums.RoadTypeEnums;
    createVariant: CreateVariantEnums.CreateVariantEnums;
    overrideRoadConfig: OverrideRoadConfig.OverrideRoadConfig;
    
    fromPositionVector2Data: PointVector2Data.PointVector2Data;
    toPositionVector2Data: PointVector2Data.PointVector2Data?;
}

return function(
    roadType: RoadTypeEnums.RoadTypeEnums,
    createVariant: CreateVariantEnums.CreateVariantEnums,
    overrideRoadConfig: OverrideRoadConfig.OverrideRoadConfig,

    fromPositionVector2Data: PointVector2Data.PointVector2Data,
    toPositionVector2Data: PointVector2Data.PointVector2Data?
): CreateRoadConfig
    
    return {
        roadType = roadType;
        createVariant = createVariant;
        overrideRoadConfig = overrideRoadConfig;
        
        fromPositionVector2Data = fromPositionVector2Data;
        toPositionVector2Data = toPositionVector2Data;
    }
end
