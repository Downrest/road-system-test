local ReplicatedStorage = game:GetService("ReplicatedStorage")

local OverrideRoadConfig = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.OverrideRoadConfig)
local PointVector2Data = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.PointVector2Data)

export type CreateRoadConfig = {
    roadType: string;
    roadVariant: string;
    overrideRoadConfig: OverrideRoadConfig.OverrideRoadConfig;
    
    fromPositionVector2Data: PointVector2Data.PointVector2Data;
    toPositionVector2Data: PointVector2Data.PointVector2Data?;
}

return function(
    roadType: string,
    roadVariant: string,
    overrideRoadConfig: OverrideRoadConfig.OverrideRoadConfig,

    fromPositionVector2Data: PointVector2Data.PointVector2Data,
    toPositionVector2Data: PointVector2Data.PointVector2Data?
): CreateRoadConfig
    return {
        roadType = roadType;
        roadVariant = roadVariant;
        overrideRoadConfig = overrideRoadConfig;
        
        fromPositionVector2Data = fromPositionVector2Data;
        toPositionVector2Data = toPositionVector2Data;
    }
end
