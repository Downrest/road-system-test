export type ExtensionConfigData = {
    isEndPoint: boolean;
    endPointDependents: {
        roadPoints: {BasePart};
        roads: {BasePart};
    };

    originRoadPoint: BasePart;
}

return function(
    isEndPoint: boolean,
    originRoadPoint: BasePart,
    
    dependentRoadPoints: {BasePart},
    dependentRoads: {BasePart}
): ExtensionConfigData
    return {
        isEndPoint = isEndPoint;
        endPointDependents = {
            roadPoints = dependentRoadPoints;
            roads = dependentRoads;
        };
        originRoadPoint = originRoadPoint;
    }
end
