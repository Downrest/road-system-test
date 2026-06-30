type RoadInstance<roadReference = BasePart> = roadReference
export type RoadCache<roadReference = BasePart> = {
    dependeeRoadPoints: {RoadInstance<roadReference>};
}

return function<roadReference>(
    dependeeRoadPoints: {RoadInstance<roadReference>}
): RoadCache
    return {
        dependeeRoadPoints = dependeeRoadPoints;
    }
end