local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DependentPointConfig = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.CacheDataWrappers.PointConfigWrappers.DependentPointConfig)
local EndPointConfig = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.CacheDataWrappers.PointConfigWrappers.EndPointConfig)
local RoadPointCacheTypeEnums = require(ReplicatedStorage.RoadBuilder.RoadBuilderEnums.RoadPointCacheTypeEnums)
local RoadVariantEnums = require(ReplicatedStorage.RoadBuilder.RoadBuilderEnums.RoadVariantEnums)

type RoadInstance<roadReference = BasePart> = roadReference
export type RoadPointCache<roadReference = BasePart> = {
    roadVariant: RoadVariantEnums.RoadVariantEnums;
    roadPointCacheType: RoadPointCacheTypeEnums.RoadPointCacheTypes,
    roadPointConfig: EndPointConfig.EndPointConfig | DependentPointConfig.DependentPointConfig,
    vector2Direction: Vector2
}

return function<roadReference>(
    roadPointCacheType: RoadPointCacheTypeEnums.RoadPointCacheTypes?,
    roadPointConfig: EndPointConfig.EndPointConfig | DependentPointConfig.DependentPointConfig,
    vector2Direction: Vector2
): RoadPointCache
    return {
        roadVariant = RoadVariantEnums.RoadPoint;
        roadPointCacheType = roadPointCacheType or RoadPointCacheTypeEnums.DependentPoint;
        roadPointConfig = roadPointConfig;
        vector2Direction = vector2Direction;
    }
end
