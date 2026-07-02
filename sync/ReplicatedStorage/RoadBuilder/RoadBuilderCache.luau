local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local RoadCache = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.CacheDataWrappers.RoadCache)
local RoadPointCache = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.CacheDataWrappers.RoadPointCache)
local RoadVariantEnums = require(ReplicatedStorage.RoadBuilder.RoadBuilderEnums.RoadVariantEnums)
local RoadBuilderEvents = require(ReplicatedStorage.RoadBuilder.RoadBuilderEvents)
local Signal = require(ReplicatedStorage.SharedPackages.Signal)
local SpatialHash = require(ReplicatedStorage.SharedPackages.SpatialHash)
local TableUtils = require(ReplicatedStorage.SharedUtils.TableUtils)

local Cache = {}

type RoadPointCacheList = {[BasePart]: RoadPointCache.RoadPointCache}
type RoadCacheList = {[BasePart]: RoadCache.RoadCache}
type Vector3ToRoadInstanceCacheList = {[Vector3]: BasePart}

type RoadCaches = RoadCache.RoadCache<BasePart> | RoadPointCache.RoadPointCache<BasePart>

type TargetRoad = "TargetRoad"
type TargetRoadPoint = "TargetRoadPoint"
type TargetCacheTypes = TargetRoad | TargetRoadPoint

type RoadReplicationCache = {
    roadInstance: BasePart;
    roadCacheData: RoadCaches;
    targetCacheType: TargetCacheTypes;
}

local HASH_CELL_SIZE = 50

Cache.RoadPointCacheList = {}:: RoadPointCacheList
Cache.RoadCacheList = {}:: RoadCacheList
Cache.Vector3ToRoadInstanceCacheList = {}:: Vector3ToRoadInstanceCacheList

Cache.RoadInstanceHash = {
    roadPoints = SpatialHash.new<<{[BasePart]: RoadPointCache.RoadPointCache}>>(HASH_CELL_SIZE);
    roads = SpatialHash.new<<{[BasePart]: RoadCache.RoadCache}>>(HASH_CELL_SIZE);
}

Cache.TARGET_CACHE_TYPE_ENUMS = {
    TargetRoad = "TargetRoad";
    TargetRoadPoint = "TargetRoadPoint";
}

local dataListeners: {[Vector3]: Signal.Signal<(roadCache: RoadCaches) -> ()>} = {}
local replicateRoadDataEvent = RoadBuilderEvents.ReplicateRoadData

local function setRoadInstanceCache(
    roadInstance: BasePart, 
    roadInstanceCache: RoadCaches
)
    local wasCacheExisting = true
    if not roadInstanceCache then
        wasCacheExisting = false

        roadInstanceCache = Cache.GetRoadDataFromVector3(roadInstance.Position)
        if not roadInstanceCache then -- if still nothing, just return
            return
        end
    end

    local isRoadPoint = (roadInstanceCache.roadVariant == RoadVariantEnums.RoadPoint)
    local cacheList = isRoadPoint
        and Cache.RoadPointCacheList
        or Cache.RoadCacheList
    local hashList = isRoadPoint
        and Cache.RoadInstanceHash.roadPoints
        or Cache.RoadInstanceHash.roads

    cacheList[roadInstance] = roadInstanceCache
    Cache.Vector3ToRoadInstanceCacheList[roadInstance.Position] = wasCacheExisting and roadInstance

    if wasCacheExisting then
        hashList:PushValue(roadInstance.Position, roadInstance, roadInstanceCache)
    else
        hashList:PopValue(roadInstance.Position, roadInstance, roadInstanceCache)
    end
end

if RunService:IsClient() then
	replicateRoadDataEvent.OnClientEvent:Connect(function(batchedReplicateQueue: {RoadReplicationCache})
        for _, replicationCache in batchedReplicateQueue do
            -- local cacheList = replicationCache.targetCacheType == Cache.TARGET_CACHE_TYPE_ENUMS.TargetRoadPoint
            --     and Cache.RoadPointCacheList
            --     or Cache.RoadCacheList

            local roadInstance = replicationCache.roadInstance
            local roadCache = replicationCache.roadCacheData

            -- cacheList[roadInstance] = roadData
            -- Cache.Vector3ToRoadInstanceCacheList[roadInstance.Position] = roadInstance
            setRoadInstanceCache(roadInstance, roadCache)

            -- trigger data listeners (for now, data can only be vector3's)
            for data, listener in dataListeners do
                if Cache.Vector3ToRoadInstanceCacheList[data] then
                    listener:Fire(roadInstance, roadCache)
                end
            end
        end
    end)

else
    local toBatchReplicateQueue: {[BasePart]: RoadReplicationCache} = {}

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
        replicateRoadDataEvent:FireAllClients(TableUtils.GetValues(toBatchReplicateQueue))
       
        table.clear(toBatchReplicateQueue)
    end

    function Cache.QueueReplicationCache(
        roadInstance: BasePart,
        roadCacheData: RoadCaches,
        targetCacheType: TargetCacheTypes
    )
        -- this implies overriding behavior
        toBatchReplicateQueue[roadInstance] = newRoadReplicationCache(
            roadInstance,
            roadCacheData,
            targetCacheType
        )
    end

    --[[
        SETTERS
    ]]

	function Cache.SetRoadPointCache(
        roadPoint: BasePart, 
        roadPointCache: RoadPointCache.RoadPointCache,
        forceReplication: boolean?
    )
        setRoadInstanceCache(roadPoint, roadPointCache)
		-- Cache.RoadPointCacheList[roadPoint] = roadPointCache
		-- Cache.Vector3ToRoadInstanceCacheList[roadPoint.Position] = roadPoint

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
        setRoadInstanceCache(road, roadCache)
		-- Cache.RoadCacheList[road] = roadCache
		-- Cache.Vector3ToRoadInstanceCacheList[road.Position] = road

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
        setRoadInstanceCache(roadPoint, nil)
		-- Cache.RoadPointCacheList[roadPoint] = nil
		-- Cache.Vector3ToRoadInstanceCacheList[roadPoint.Position] = nil

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
        setRoadInstanceCache(road, nil)
		-- Cache.RoadCacheList[road] = nil
		-- Cache.Vector3ToRoadInstanceCacheList[road.Position] = nil

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
    LISTENERS
]]

function Cache.ListenOnceForVector3(
    vector3: Vector3, 
    callback: (
        roadInstance: BasePart, 
        roadCache: RoadCaches, 
        listenDestructor: () -> ()?
    ) -> ()
)
    local existingRoadPoint = Cache.GetRoadInstanceFromVector3(vector3)
    local existingRoadPointCache = existingRoadPoint and Cache.GetRoadPointCache(existingRoadPoint)

    -- already exists, no need for any signal/listener creation
    if existingRoadPointCache then
        callback(existingRoadPoint, existingRoadPointCache)

    -- does not exist, create signal/listener
    else
        local listenerSignal = Signal.new()
        dataListeners[vector3] = listenerSignal

        -- gives us an option to disconnect whenever we want
        local function listenDestructor()
            dataListeners[vector3] = nil
            listenerSignal:Destroy()
        end

        listenerSignal:Connect(function(
            roadInstance: BasePart, 
            roadCache: RoadCaches
        )
            callback(roadInstance, roadCache, listenDestructor)
        end)
    end
end

function Cache.DestroyVector3Listener(vector3: Vector3)
    local listenerSignal = dataListeners[vector3]
    if not listenerSignal then
        return
    end

    listenerSignal:Destroy()
    dataListeners[vector3] = nil
end

function Cache.DestroyAllListeners()
    for listenerData, listenerSignal in dataListeners do
        listenerSignal:Destroy()
        dataListeners[listenerData] = nil
    end
end

--[[
    GETTERS
]]

-- cache getter

function Cache.GetRoadInstanceFromVector3(vector3: Vector3): BasePart?
	return Cache.Vector3ToRoadInstanceCacheList[vector3]
end

function Cache.GetRoadDataFromVector3(vector3: Vector3): (RoadPointCache.RoadPointCache | RoadCache.RoadCache)?
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

-- instance getters

function Cache.GetRoadPointInstances(): {BasePart}
    local roadPointInstances = {}

    for roadPoint in Cache.RoadPointCacheList do
        table.insert(roadPointInstances, roadPoint)
    end

    return roadPointInstances
end

function Cache.GetRoadInstances(): {BasePart}
    local roadInstances = {}

    for roadPoint in Cache.RoadCacheList do
        table.insert(roadInstances, roadPoint)
    end

    return roadInstances
end

return Cache