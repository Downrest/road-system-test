local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PointVector2Data = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.PointVector2Data)

export type RoadCreationOutput = {
    endRoadPointInstance: BasePart,
    endRoadPointVector2Data: PointVector2Data.PointVector2Data,
    dependentRoadInstances: {BasePart}?
}

return function(
	endRoadPointInstance: BasePart,
    endRoadPointVector2Data: PointVector2Data.PointVector2Data,

    dependentRoadInstances: {BasePart}?
): RoadCreationOutput
	return {
		endRoadPointInstance = endRoadPointInstance,
        endRoadPointVector2Data = endRoadPointVector2Data,

        dependentRoadInstances = dependentRoadInstances
    }
end