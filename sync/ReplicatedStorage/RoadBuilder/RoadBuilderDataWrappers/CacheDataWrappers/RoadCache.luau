local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RoadVariantEnums = require(ReplicatedStorage.RoadBuilder.RoadBuilderEnums.RoadVariantEnums)
--TODO: REMOVE THE ROADREFERNECE, JUST MAKE IT BASEPART

type RoadInstance<roadReference = BasePart> = roadReference
export type RoadCache<roadReference = BasePart> = {
    roadVariant: RoadVariantEnums.RoadVariantEnums;
    dependeeRoadPoints: {RoadInstance<roadReference>};
    connectedRoadPoints: {RoadInstance<roadReference>};
}

return function<roadReference>(
    dependeeRoadPoints: {RoadInstance<roadReference>},
    connectedRoadPoints: {RoadInstance<roadReference>}
): RoadCache
    return {
        roadVariant = RoadVariantEnums.Road;
        dependeeRoadPoints = dependeeRoadPoints;
        connectedRoadPoints = connectedRoadPoints;
    }
end