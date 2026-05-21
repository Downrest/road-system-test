local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RoadCache = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.CacheDataWrappers.RoadCache)
local RoadPointCache = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.CacheDataWrappers.RoadPointCache)
local CacheTypeEnums = require(ReplicatedStorage.RoadBuilder.RoadBuilderEnums.CacheTypeEnums)
local RoadBuilderEvents = require(ReplicatedStorage.RoadBuilder.RoadBuilderEvents)

local Cache = {}

Cache.RoadPointCacheList = {}
Cache.RoadCacheList = {}
Cache.Vector3ToRoadInstanceCacheList = {}

--[[
    SETTERS
]]

function Cache.AddRoadPoint(roadPoint: BasePart, roadPointCache: RoadPointCache.type)
    Cache.RoadPointCacheList[roadPoint] = roadPointCache
	Cache.Vector3ToRoadInstanceCacheList[roadPoint.Position] = roadPoint
    RoadBuilderEvents.UpdateClientCache:FireServer(CacheTypeEnums.RoadPointCache, roadPoint, roadPointCache)
end

function Cache.AddRoad(road: BasePart, roadCache: RoadCache.type)
    Cache.RoadCacheList[road] = roadCache
	Cache.Vector3ToRoadInstanceCacheList[road.Position] = road
    RoadBuilderEvents.UpdateClientCache:FireServer(CacheTypeEnums.RoadCache, road, roadCache)
end

function Cache.AddDependentRoadsToRoadPoint(insertedDependentRoads: {BasePart}, roadPoint: BasePart)
    local roadPointDependentRoads = Cache.RoadPointCacheList[roadPoint].dependentRoads
    local ROAD_POINT_DEPENDENT_ROADS_LENGTH = #roadPointDependentRoads

    table.move(
        insertedDependentRoads, 1, #insertedDependentRoads,
        ROAD_POINT_DEPENDENT_ROADS_LENGTH+1, roadPointDependentRoads
    )
end

--[[
    GETTERS
]]

function Cache.GetRoadInstanceFromVector3(vector3: Vector3): BasePart?
    return Cache.Vector3ToRoadInstanceCacheList[vector3]
end

return Cache