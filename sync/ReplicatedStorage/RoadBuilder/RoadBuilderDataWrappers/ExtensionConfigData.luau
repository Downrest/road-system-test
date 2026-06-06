export type ExtensionConfigData = {
    isEndPoint: boolean;
    endPointDependents: {BasePart};

    originRoadPoint: BasePart;
}

return function(
    isEndPoint: boolean,
    originRoadPoint: BasePart,
    endPointDependents: {BasePart}
): ExtensionConfigData
    return {
        isEndPoint = isEndPoint;
        endPointDependents = endPointDependents;

        originRoadPoint = originRoadPoint;
    }
end
