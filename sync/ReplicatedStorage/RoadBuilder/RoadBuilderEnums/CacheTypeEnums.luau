export type RoadPointCacheType = "RoadPointCache"
export type RoadCacheType = "RoadCache"
export type CacheTypeEnums = RoadPointCacheType | RoadCacheType

type CacheTypeEnumsTable = {
    RoadPointCache: RoadPointCacheType;
    RoadCache: CacheTypeEnums;
}

return {
    RoadPointCache = "RoadPointCache";
    RoadCache = "RoadCache";
}:: CacheTypeEnumsTable