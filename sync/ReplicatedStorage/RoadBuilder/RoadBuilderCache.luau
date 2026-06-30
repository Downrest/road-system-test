local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local RoadCreationConfig = require(ReplicatedStorage.RoadBuilder.RoadBuilderConfig.RoadCreationConfig)
local RoadCache = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.CacheDataWrappers.RoadCache)
local RoadPointCache = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.CacheDataWrappers.RoadPointCache)
local RoadBuilderEvents = require(ReplicatedStorage.RoadBuilder.RoadBuilderEvents)
local Signal = require(ReplicatedStorage.SharedPackages.Signal)
local batch = require(ReplicatedStorage.SharedPackages.Vide.batch)
local TableUtils = require(ReplicatedStorage.SharedUtils.TableUtils)

local Cache = {}

type RoadPointCacheList = {[BasePart]: RoadPointCache.RoadPointCache}
type RoadCacheList = {[BasePart]: RoadCache.RoadCache}
type Vector3ToRoadInstanceCacheList = {[Vector3]: BasePart}

type RoadCaches = RoadCache.RoadCache<Vector3> | RoadPointCache.RoadPointCache<Vector3>

type TargetRoad = "TargetRoad"
type TargetRoadPoint = "TargetRoadPoint"
type TargetCacheTypes = TargetRoad | TargetRoadPoint

type RoadReplicationCache = {
    roadInstance: BasePart;
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

local dataListeners: {[Vector3]: Signal.Signal<(roadCache: RoadCaches) -> ()>} = {}
local replicateRoadDataEvent = RoadBuilderEvents.ReplicateRoadData

if RunService:IsClient() then
	replicateRoadDataEvent.OnClientEvent:Connect(function(batchedReplicateQueue: {RoadReplicationCache})
        for _, replicationCache in batchedReplicateQueue do
            local cacheList = replicationCache.targetCacheType == Cache.TARGET_CACHE_TYPE_ENUMS.TargetRoadPoint
                and Cache.RoadPointCacheList
                or Cache.RoadCacheList

            local roadInstance = replicationCache.roadInstance
            local roadData = replicationCache.roadCacheData

            cacheList[roadInstance] = roadData
            Cache.Vector3ToRoadInstanceCacheList[roadInstance.Position] = roadInstance

            -- trigger data listeners (for now, data can only be vector3's)
            for data, listener in dataListeners do
                if Cache.Vector3ToRoadInstanceCacheList[data] then
                    listener:Fire(roadData)
                end
            end
        end
    end)

else
    local toBatchReplicateQueue: {RoadReplicationCache} = {}

    local function newRoadReplicationCache(
        roadInstance: BasePart,
        roadCacheData: RoadCaches,
        targetCacheType: TargetCacheTypes
    ): RoadReplicationCache
        return {
            roadInstance = roadInstance;
            roadCacheData = roadCacheData;
            targetCacheType = targetCacheType;
        }
    end

    --[[
        PLAYER ADDED
    ]]

    function Cache.SendAllReplicationCache(players: (Player | {Player})?)
        assert(players, "Failed to replicate all cache because `players` is empty")
        players = TableUtils.EnsureTable(players)

        local allCache: {RoadReplicationCache} = {}

        for roadPointInstance, roadPointData in Cache.RoadPointCacheList do
            table.insert(allCache, newRoadReplicationCache(
                roadPointInstance,
                roadPointData,
                Cache.TARGET_CACHE_TYPE_ENUMS.TargetRoadPoint
            ))
        end
        for roadInstance, roadData in Cache.RoadCacheList do
            table.insert(allCache, newRoadReplicationCache(
                roadInstance,
                roadData,
                Cache.TARGET_CACHE_TYPE_ENUMS.TargetRoad
            ))
        end

        for _, player in players do
            replicateRoadDataEvent:FireClient(player, allCache)
        end
    end

    --[[
        BATCHER (FOR CURRENT PLAYERS)
    ]]

    function Cache.SendBatchedReplicationCache()
        replicateRoadDataEvent:FireAllClients(toBatchReplicateQueue)
       
        table.clear(toBatchReplicateQueue)
    end

    function Cache.QueueReplicationCache(
        roadInstance: BasePart,
        roadCacheData: RoadCaches,
        targetCacheType: TargetCacheTypes
    )
        table.insert(toBatchReplicateQueue, newRoadReplicationCache(
            roadInstance,
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
            roadPoint,
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
            road,
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
            roadPoint,
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
            road,
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

function Cache.ListenOnceForVector3(vector3: Vector3, callback: (roadCache: RoadCaches) -> ())
    local signal = Signal.new()
    dataListeners[vector3] = signal

    signal:Once(function(roadCache: RoadCaches)
        callback(roadCache)

        signal:Destroy()
        dataListeners[vector3] = nil
    end)
end

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