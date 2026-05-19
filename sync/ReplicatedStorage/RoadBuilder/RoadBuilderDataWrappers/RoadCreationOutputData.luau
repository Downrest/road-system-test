local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PointVector2Data = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.PointVector2Data)

export type type = {
    endRoadPointInstance: BasePart,
    endRoadPointVector2Data: PointVector2Data.type,
    dependentRoadInstances: {BasePart}?
}

return function(
	endRoadPointInstance: BasePart,
    endRoadPointVector2Data: PointVector2Data.type,

    dependentRoadInstances: {BasePart}?
): type
	return {
		endRoadPointInstance = endRoadPointInstance,
        endRoadPointVector2Data = endRoadPointVector2Data,

        dependentRoadInstances = dependentRoadInstances
    }
end