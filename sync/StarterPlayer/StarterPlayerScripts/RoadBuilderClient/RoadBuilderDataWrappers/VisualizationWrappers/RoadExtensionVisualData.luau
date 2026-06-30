local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PointVector2Data = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.PointVector2Data)

export type RoadExtensionVisualData = {
    endRoadPointInstance: BasePart;
    endRoadPointVector2Data: PointVector2Data.PointVector2Data;
    dependentRoadInstances: {
        n: number;
        roadPoints: {BasePart};
        roads: {BasePart};
    };
    destructor: () -> ();
}

return function(
    endRoadPointInstance: BasePart,
    endRoadPointVector2Data: PointVector2Data.PointVector2Data,
    dependentRoadInstances: {BasePart},
    destructor: () -> ()
): RoadExtensionVisualData
    return {
        endRoadPointInstance = endRoadPointInstance;
        endRoadPointVector2Data = endRoadPointVector2Data;
        dependentRoadInstances = dependentRoadInstances;
        
        destructor = destructor;
    }
end
