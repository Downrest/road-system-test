local ReplicatedStorage = game:GetService("ReplicatedStorage")

local OverrideRoadEnums = require(ReplicatedStorage.RoadBuilder.RoadBuilderEnums.OverrideRoadEnums)
local RoadPointCacheTypeEnums = require(ReplicatedStorage.RoadBuilder.RoadBuilderEnums.RoadPointCacheTypeEnums)
local TableUtils = require(ReplicatedStorage.SharedUtils.TableUtils)

export type SetPointCacheType = {
    tag: OverrideRoadEnums.SetPointCacheTypeOverride;
    pointCacheType: RoadPointCacheTypeEnums.RoadPointCacheTypes;
    pointPositions: {Vector3};
}

return function(
    pointCacheType: RoadPointCacheTypeEnums.RoadPointCacheTypes,
    pointPositions: Vector3 | {Vector3}
): SetPointCacheType
    pointPositions = TableUtils.EnsureTable(pointPositions)

    return {
        tag = OverrideRoadEnums.SetPointCacheType;
        pointCacheType = pointCacheType;
        pointPositions = pointPositions;
    }
end
