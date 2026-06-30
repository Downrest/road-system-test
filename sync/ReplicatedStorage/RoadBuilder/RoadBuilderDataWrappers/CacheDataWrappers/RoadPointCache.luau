local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RoadPointCacheTypeEnums = require(ReplicatedStorage.RoadBuilder.RoadBuilderEnums.RoadPointCacheTypeEnums)

type RoadInstance<roadReference = BasePart> = roadReference
export type RoadPointCache<roadReference = BasePart> = {
    roadPointCacheType: RoadPointCacheTypeEnums.RoadPointCacheTypes,
    pairExtensionEndRoadPoints: {RoadInstance<roadReference>?},
    dependentRoadInstances: {
        roadPoints: {RoadInstance<roadReference>?};
        roads: {RoadInstance<roadReference>?};
    },
    vector2Direction: Vector2
}

return function<roadReference>(
    roadPointCacheType: RoadPointCacheTypeEnums.RoadPointCacheTypes?,
    pairExtensionEndRoadPoints: {RoadInstance<roadReference>?},

    dependentRoadPoints: {RoadInstance<roadReference>},
    dependentRoads: {RoadInstance<roadReference>},
    
    vector2Direction: Vector2
): RoadPointCache
    return {
        roadPointCacheType = roadPointCacheType or RoadPointCacheTypeEnums.DependentPoint;
        pairExtensionEndRoadPoints = pairExtensionEndRoadPoints;

        dependentRoadInstances = {
            roadPoints = dependentRoadPoints;
            roads = dependentRoads;
        };

        vector2Direction = vector2Direction;
    }
end
