local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PointVector2Data = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.PointVector2Data)

export type RoadCreationOutputData = {
    endRoadPointInstance: BasePart,
    endRoadPointVector2Data: PointVector2Data.PointVector2Data,
    dependentRoadInstances: {
        roads: {BasePart};
        roadPoints: {BasePart};
        n: number;
    }?
}

return function(
	endRoadPointInstance: BasePart,
    endRoadPointVector2Data: PointVector2Data.PointVector2Data,

    dependentRoadInstances: {
        roads: {BasePart};
        roadPoints: {BasePart};
        n: number;
    }?
): RoadCreationOutputData
	return {
		endRoadPointInstance = endRoadPointInstance,
        endRoadPointVector2Data = endRoadPointVector2Data,

        dependentRoadInstances = dependentRoadInstances
    }
end