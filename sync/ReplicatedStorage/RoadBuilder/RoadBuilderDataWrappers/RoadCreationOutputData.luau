local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PointVector2Data = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.PointVector2Data)

export type type = {
    endRoadInstance: BasePart,
    endPointVector2: PointVector2Data.type
}

return function(
	endRoadInstance: BasePart,
    endPointVector2: PointVector2Data.type
): type
	return {
		endRoadInstance = endRoadInstance,
        endRoadPointVector2 = endPointVector2
    }
end