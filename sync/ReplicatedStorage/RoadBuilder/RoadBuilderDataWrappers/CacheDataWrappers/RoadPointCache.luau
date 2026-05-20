export type type = {
    dependentRoads: {BasePart},
    vector2Direction: Vector2
}

return function(
    dependentRoads: {BasePart},
    vector2Direction: Vector2
): type
    return {
        dependentRoads = dependentRoads;
        vector2Direction = vector2Direction;
    }
end
