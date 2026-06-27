local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RoadCache = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.CacheDataWrappers.RoadCache)
local RoadPointCache = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.CacheDataWrappers.RoadPointCache)

local Cache = {}

Cache.RoadPointCacheList = {}
Cache.RoadCacheList = {}
Cache.Vector3ToRoadInstanceCacheList = {}

--[[
    SETTERS
]]

function Cache.SetRoadPointCache(roadPoint: BasePart, roadPointCache: RoadPointCache.RoadPointCache)
    Cache.RoadPointCacheList[roadPoint] = roadPointCache
	Cache.Vector3ToRoadInstanceCacheList[roadPoint.Position] = roadPoint
end

function Cache.SetRoadCache(road: BasePart, roadCache: RoadCache.RoadCache)
    Cache.RoadCacheList[road] = roadCache
	Cache.Vector3ToRoadInstanceCacheList[road.Position] = road
end

--[[
    DESTRUCTORS
]]

function Cache.ClearRoadPointCache(roadPoint: BasePart)
    Cache.RoadPointCacheList[roadPoint] = nil
	Cache.Vector3ToRoadInstanceCacheList[roadPoint.Position] = nil
end

function Cache.ClearRoadCache(road: BasePart)
    Cache.RoadCacheList[road] = nil
	Cache.Vector3ToRoadInstanceCacheList[road.Position] = nil
end

--[[
    GETTERS
]]

function Cache.GetRoadInstanceFromVector3(vector3: Vector3): BasePart?
    return Cache.Vector3ToRoadInstanceCacheList[vector3]
end

function Cache.GetRoadPointCache(roadPoint: BasePart): RoadPointCache.RoadPointCache?
    return Cache.RoadPointCacheList[roadPoint]
end

function Cache.GetRoadCache(road: BasePart): RoadCache.RoadCache?
    return Cache.RoadCacheList[road]
end

return Cache