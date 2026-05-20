export type type = {
    dependeeRoadPoints: {BasePart};
}

return function(
    dependeeRoadPoints: {BasePart}
): type
    return {
        roadPoints = dependeeRoadPoints;
    }
end