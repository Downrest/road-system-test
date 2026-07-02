local ReplicatedStorage = game:GetService("ReplicatedStorage")

local OverrideRoadEnums = require(ReplicatedStorage.RoadBuilder.RoadBuilderEnums.OverrideRoadEnums)
local TableUtils = require(ReplicatedStorage.SharedUtils.TableUtils)

export type ClearPreviousRoad = {
    tag: OverrideRoadEnums.ClearPreviousRoadOverride;
    clearPointPositions: {Vector3};
}

return function(
    clearPointPositions: Vector3 | {Vector3}
): ClearPreviousRoad
    clearPointPositions = TableUtils.EnsureTable(clearPointPositions)

    return {
        tag = OverrideRoadEnums.ClearPreviousRoadOverride;
        clearPointPositions = clearPointPositions;
    }
end
