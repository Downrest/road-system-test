local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local RoadCreationConfig = require(ReplicatedStorage.RoadBuilder.RoadBuilderConfig.RoadCreationConfig)
local RoadCache = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.CacheDataWrappers.RoadCache)
local RoadPointCache = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.CacheDataWrappers.RoadPointCache)
local RoadBuilderEvents = require(ReplicatedStorage.RoadBuilder.RoadBuilderEvents)

local Cache = {}

type RoadPointCacheList = {[BasePart]: RoadPointCache.RoadPointCache}
type RoadCacheList = {[BasePart]: RoadCache.RoadCache}
type Vector3ToRoadInstanceCacheList = {[Vector3]: BasePart}

type RoadCaches = RoadCache.RoadCache | RoadPointCache.RoadPointCache

type TargetRoad = "TargetRoad"
type TargetRoadPoint = "TargetRoadPoint"
type TargetCacheTypes = TargetRoad | TargetRoadPoint

type RoadReplicationCache = {
    roadInstancePosition: Vector3;
    roadCacheData: RoadCaches;
    targetCacheType: TargetCacheTypes;
}

Cache.RoadPointCacheList = {}:: RoadPointCacheList
Cache.RoadCacheList = {}:: RoadCacheList
Cache.Vector3ToRoadInstanceCacheList = {}:: Vector3ToRoadInstanceCacheList

Cache.TARGET_CACHE_TYPE_ENUMS = {
    TargetRoad = "TargetRoad";
    TargetRoadPoint = "TargetRoadPoint";
}

local replicateRoadDataEvent = RoadBuilderEvents.ReplicateRoadData

if RunService:IsClient() then
    local roadReplicationQueue: {RoadReplicationCache} = {}

	replicateRoadDataEvent.OnClientEvent:Connect(function(batchedRoadReplicationCache: {RoadReplicationCache})
        for _, replicationCache in batchedRoadReplicationCache do
            local cachedRoadInstance = Cache.Vector3ToRoadInstanceCacheList[replicationCache.roadInstancePosition]

            -- override current cache
            if cachedRoadInstance then
                local cacheList = (replicationCache.targetCacheType == Cache.TARGET_CACHE_TYPE_ENUMS.TargetRoad)
                    and Cache.RoadCacheList[cachedRoadInstance]
                    or Cache.RoadPointCacheList[cachedRoadInstance]

                cacheList = replicationCache.roadCacheData
                warn("EXISTENT")
                
            -- put into replication queue (which will eventually update cache)
            else
                table.insert(roadReplicationQueue, replicationCache)
                warn("NEW")
            end
        end
    end)

    RoadCreationConfig.ROAD_PARENTS.roadPoint.ChildAdded:Connect(function(roadInstance: BasePart)
        local roadInstancePosition = roadInstance.Position

        for queueIndex, replicationQueue in roadReplicationQueue do
            if 
                replicationQueue.roadInstancePosition ~= roadInstancePosition 
                and replicationQueue.targetCacheType == Cache.TARGET_CACHE_TYPE_ENUMS.TargetRoadPoint
            then
                continue
            end

            Cache.RoadPointCacheList[roadInstance] = replicationQueue.roadCacheData
            Cache.Vector3ToRoadInstanceCacheList[roadInstancePosition] = roadInstance
            table.remove(roadReplicationQueue, queueIndex)
            warn("FAJWDHWDH ADH")
            break
        end
    end)

    RoadCreationConfig.ROAD_PARENTS.road.ChildAdded:Connect(function(roadInstance: BasePart)
        local roadInstancePosition = roadInstance.Position

        for queueIndex, replicationQueue in roadReplicationQueue do
            if 
                replicationQueue.roadInstancePosition ~= roadInstancePosition 
                and replicationQueue.targetCacheType == Cache.TARGET_CACHE_TYPE_ENUMS.TargetRoad
            then
                continue
            end

            Cache.RoadCacheList[roadInstance] = replicationQueue.roadCacheData
            Cache.Vector3ToRoadInstanceCacheList[roadInstancePosition] = roadInstance
            table.remove(roadReplicationQueue, queueIndex)
            break
        end
    end)

else
    local toBatchReplicateQueue = {}

    local function newRoadReplicationCache(
        roadInstancePosition: Vector3,
        roadCacheData: RoadCaches,
        targetCacheType: TargetCacheTypes
    ): RoadReplicationCache
        return {
            roadInstancePosition = roadInstancePosition;
            roadCacheData = roadCacheData;
            targetCacheType = targetCacheType;
        }
    end

    --[[
        BATCHER
    ]]

    function Cache.SendBatchedReplicationCache()
        replicateRoadDataEvent:FireAllClients(toBatchReplicateQueue)
        table.clear(toBatchReplicateQueue)
    end

    function Cache.QueueReplicationCache(
        roadInstancePosition: Vector3,
        roadCacheData: RoadCaches,
        targetCacheType: TargetCacheTypes
    )
        table.insert(toBatchReplicateQueue, newRoadReplicationCache(
            roadInstancePosition,
            roadCacheData,
            targetCacheType
        ))
    end

    --[[
        SETTERS
    ]]

	function Cache.SetRoadPointCache(
        roadPoint: BasePart, 
        roadPointCache: RoadPointCache.RoadPointCache,
        forceReplication: boolean?
    )
		Cache.RoadPointCacheList[roadPoint] = roadPointCache
		Cache.Vector3ToRoadInstanceCacheList[roadPoint.Position] = roadPoint

        Cache.QueueReplicationCache(
            roadPoint.Position,
            roadPointCache,
            Cache.TARGET_CACHE_TYPE_ENUMS.TargetRoadPoint
        )
        if forceReplication then
            Cache.SendBatchedReplicationCache()
        end
	end

	function Cache.SetRoadCache(
        road: BasePart, 
        roadCache: RoadCache.RoadCache,
        forceReplication: boolean?
    )
		Cache.RoadCacheList[road] = roadCache
		Cache.Vector3ToRoadInstanceCacheList[road.Position] = road

        Cache.QueueReplicationCache(
            road.Position,
            roadCache,
            Cache.TARGET_CACHE_TYPE_ENUMS.TargetRoad
        )
        if forceReplication then
            Cache.SendBatchedReplicationCache()
        end
	end

    --[[
        DESTRUCTORS
    ]]

	function Cache.ClearRoadPointCache(
        roadPoint: BasePart,
        forceReplication: boolean?
    )
		Cache.RoadPointCacheList[roadPoint] = nil
		Cache.Vector3ToRoadInstanceCacheList[roadPoint.Position] = nil

        Cache.QueueReplicationCache(
            roadPoint.Position,
            nil,
            Cache.TARGET_CACHE_TYPE_ENUMS.TargetRoadPoint
        )
        if forceReplication then
            Cache.SendBatchedReplicationCache()
        end
	end

	function Cache.ClearRoadCache(
        road: BasePart,
        forceReplication: boolean?
    )
		Cache.RoadCacheList[road] = nil
		Cache.Vector3ToRoadInstanceCacheList[road.Position] = nil

        Cache.QueueReplicationCache(
            road.Position,
            nil,
            Cache.TARGET_CACHE_TYPE_ENUMS.TargetRoad
        )
        if forceReplication then
            Cache.SendBatchedReplicationCache()
        end
	end
end

--[[
    GETTERS
]]

function Cache.GetRoadInstanceFromVector3(vector3: Vector3): BasePart?
	return Cache.Vector3ToRoadInstanceCacheList[vector3]
end

function Cache.GetRoadDataFromVector3(vector3: Vector3): BasePart?
    local roadInstance = Cache.GetRoadInstanceFromVector3(vector3)
    if not roadInstance then
        return
    end

	return Cache.GetRoadPointCache(roadInstance) or Cache.GetRoadCache(roadInstance)
end

function Cache.GetRoadPointCache(roadPoint: BasePart): RoadPointCache.RoadPointCache?
	return Cache.RoadPointCacheList[roadPoint]
end

function Cache.GetRoadCache(road: BasePart): RoadCache.RoadCache?
	return Cache.RoadCacheList[road]
end

return Cache