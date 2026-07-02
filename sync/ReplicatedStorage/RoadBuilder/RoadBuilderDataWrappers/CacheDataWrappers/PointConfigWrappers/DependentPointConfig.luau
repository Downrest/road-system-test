export type DependentPointConfig = {
    dependeeRoadPoints: {BasePart};
    connectedRoads: {BasePart};
}

return function(
    dependeeRoadPoints: {BasePart},
    connectedRoads: {BasePart}
): DependentPointConfig
    return {
        dependeeRoadPoints = dependeeRoadPoints;
        connectedRoads = connectedRoads;
    }
end
