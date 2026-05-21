export type RoadCache = {
    dependeeRoadPoints: {BasePart};
}

return function(
    dependeeRoadPoints: {BasePart}
): RoadCache
    return {
        roadPoints = dependeeRoadPoints;
    }
end