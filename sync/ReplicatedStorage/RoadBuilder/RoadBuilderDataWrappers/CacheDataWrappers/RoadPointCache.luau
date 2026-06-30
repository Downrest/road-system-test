local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RoadPointCacheTypeEnums = require(ReplicatedStorage.RoadBuilder.RoadBuilderEnums.RoadPointCacheTypeEnums)

type RoadInstance<roadReference = BasePart> = roadReference
export type RoadPointCache<roadReference = BasePart> = {
    roadPointCacheType: RoadPointCacheTypeEnums.RoadPointCacheTypes,
    pairExtensionEndRoadPoints: {RoadInstance<roadReference>?},
    dependentRoads: {RoadInstance<roadReference>?},
    vector2Direction: Vector2
}

return function<roadReference>(
    roadPointCacheType: RoadPointCacheTypeEnums.RoadPointCacheTypes?,
    pairExtensionEndRoadPoints: {RoadInstance<roadReference>?},
    dependentRoads: {RoadInstance<roadReference>},
    vector2Direction: Vector2
): RoadPointCache
    return {
        roadPointCacheType = roadPointCacheType or RoadPointCacheTypeEnums.DependentPoint;
        pairExtensionEndRoadPoints = pairExtensionEndRoadPoints;
        dependentRoads = dependentRoads;
        vector2Direction = vector2Direction;
    }
end
