export type EndPointConfig = {
    pairExtensionEndRoadPoints: {BasePart};
    dependentRoadInstances: {
        roadPoints: {BasePart};
        roads: {BasePart};
    };
    connectedRoads: {BasePart};
}

return function(
    pairExtensionEndRoadPoints: {BasePart},

    dependentRoadPoints: {BasePart},
    dependentRoads: {BasePart},

    connectedRoads: {BasePart}
): EndPointConfig
    return {
        pairExtensionEndRoadPoints = pairExtensionEndRoadPoints;
        dependentRoadInstances = {
            roadPoints = dependentRoadPoints;
            roads = dependentRoads;
        };
        connectedRoads = connectedRoads;
    }
end
