export type OverrideRoadConfig = {
    shouldOverride: boolean;
    overridenRoadPointPosition: Vector3;
}

return function(
    shouldOverride: boolean,
    overridenRoadPointPosition: Vector3
): OverrideRoadConfig
    return {
        shouldOverride = shouldOverride;
        overridenRoadPointPosition = overridenRoadPointPosition;
    }
end
