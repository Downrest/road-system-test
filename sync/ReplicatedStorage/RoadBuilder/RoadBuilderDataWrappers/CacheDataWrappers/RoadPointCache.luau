export type RoadPointCache = {
    dependentRoads: {BasePart},
    vector2Direction: Vector2
}

return function(
    dependentRoads: {BasePart},
    vector2Direction: Vector2
): RoadPointCache
    return {
        dependentRoads = dependentRoads;
        vector2Direction = vector2Direction;
    }
end
