local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RoadPointCacheTypeEnums = require(ReplicatedStorage.RoadBuilder.RoadBuilderEnums.RoadPointCacheTypeEnums)
export type RoadPointCache = {
    roadPointCacheType: number,
    pairExtensionEndRoadPoints: {BasePart?},
    dependentRoads: {BasePart?},
    vector2Direction: Vector2
}

return function(
    roadPointCacheType: number?,
    pairExtensionEndRoadPoints: {BasePart?},
    dependentRoads: {BasePart},
    vector2Direction: Vector2
): RoadPointCache
    return {
        roadPointCacheType = roadPointCacheType or RoadPointCacheTypeEnums.DependentPoint;
        pairExtensionEndRoadPoints = pairExtensionEndRoadPoints;
        dependentRoads = dependentRoads;
        vector2Direction = vector2Direction;
    }
end
