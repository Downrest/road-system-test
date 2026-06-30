local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RoadBuilderCache = require(ReplicatedStorage.RoadBuilder.RoadBuilderCache)
local RoadBuilderCreation = require(ReplicatedStorage.RoadBuilder.RoadBuilderCreation)
local CreateRoadConfig = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.CreateRoadWrappers.CreateRoadConfig)
local DefaultCreateType = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.CreatePropertyWrappers.DefaultCreateType)
local OverrideRoadConfig = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.CreateRoadWrappers.OverrideRoadConfig)
local PointVector2Data = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.PointVector2Data)
local RoadConfigData = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.RoadConfigData)
local RoadCreationOutputData = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.RoadCreationOutputData)
local RoadVariantEnums = require(ReplicatedStorage.RoadBuilder.RoadBuilderEnums.RoadVariantEnums)
local RoadBuilderEvents = require(ReplicatedStorage.RoadBuilder.RoadBuilderEvents)

local function assertRoadVariant(
    roadVariant: string,
    fromPositionVector2Data: PointVector2Data.PointVector2Data,
    toPositionVector2Data: PointVector2Data.PointVector2Data?
)
    if roadVariant == RoadVariantEnums.RoadPoint then
        assert(
            fromPositionVector2Data and not toPositionVector2Data,
            "Road variant is RoadPoint, yet either `fromPosition` is nil or `toPosition` incorrectly exists"
        )
    else
        assert(
            fromPositionVector2Data and toPositionVector2Data,
            "Road variant is RoadExtension, yet either/both `fromPosition` and `toPosition` are nil"
        )
    end
end

--TODO: MOVE TO ROADBUILDERCREATION
local function overridePreviousRoad(overrideRoadConfig: OverrideRoadConfig.OverrideRoadConfig)
    if not overrideRoadConfig or not overrideRoadConfig.shouldOverride then
        return
    end

    --[[
        this refers to the `currentRemakeRoadCache.selectionRoadPoint.Position` from RoadBuilderClient.luau
        ps. we're sending positions instead of instances to avoid issues from the client-server boundary
    ]]
    local previousRoadPoint = RoadBuilderCache.Vector3ToRoadInstanceCacheList[overrideRoadConfig.overridenRoadPointPosition]
    
    local previousRoadPointCache = previousRoadPoint and RoadBuilderCache.RoadPointCacheList[previousRoadPoint]
    if not previousRoadPointCache then
        return
    end

    warn(`OVERRIDDEN!: {previousRoadPoint.Position}`)
    
    -- override via Destroy()
    previousRoadPoint:Destroy()
    for _, dependentRoad in previousRoadPointCache.dependentRoads do
        dependentRoad:Destroy()
    end

    for _, endPoint in previousRoadPointCache.pairExtensionEndRoadPoints do
        local endPointCache = RoadBuilderCache.RoadPointCacheList[endPoint]
        if not endPointCache then
            continue
        end

        local previousIndexInCache = table.find(
            endPointCache.pairExtensionEndRoadPoints,
            previousRoadPoint
        )
        if previousIndexInCache then
            table.remove(endPointCache.pairExtensionEndRoadPoints, previousIndexInCache)
        end
    end

    RoadBuilderCache.ClearRoadPointCache(previousRoadPoint)
end

--[[
    load player state for road building system
]]
--TODO: UHH NOT SURE IF UR GONNA STILL KEEP THIS LOL
Players.PlayerAdded:Connect(function(player)
    RoadBuilderCache.SendAllReplicationCache(player)
end)

--[[
    client requests road creation assuming there is available road selection data which is either
        provided via selectedRoadInstance
        PROVIDED
    
    automatically sets playerState.SelectedRoadPoint to
    the newly created road point (or if its an extension road, the very last road point)
]]
RoadBuilderEvents.CreateRoadRequest.OnServerEvent:Connect(function(
    player: Player, 
    createRoadConfig: CreateRoadConfig.CreateRoadConfig
)
    local roadType = createRoadConfig.roadType
    local roadVariant = createRoadConfig.roadVariant
    local overrideRoadConfig = createRoadConfig.overrideRoadConfig
    local fromPositionVector2Data = createRoadConfig.fromPositionVector2Data
    local toPositionVector2Data = createRoadConfig.toPositionVector2Data

    assertRoadVariant(roadVariant, fromPositionVector2Data, toPositionVector2Data)

    -- clear previous road (if applicable)
    overridePreviousRoad(overrideRoadConfig)

    local roadOutput: RoadCreationOutputData.RoadCreationOutputData

    -- step 0: create origin road
    if roadVariant == RoadVariantEnums.RoadPoint then
        roadOutput = RoadBuilderCreation.CreateOriginRoad(
            RoadConfigData(
                roadType, 
                DefaultCreateType()
            ),

            fromPositionVector2Data,
            true
        )

    -- step 1: extend from origin road
	else
        roadOutput = RoadBuilderCreation.CreateExtensionRoad(
            RoadConfigData(
                roadType, 
                DefaultCreateType()
            ),

            fromPositionVector2Data, 
            toPositionVector2Data
        )
	end

    -- toggles client's road visualization (either success or failure to create road)
	RoadBuilderEvents.CreateRoadRequest:FireClient(
		player, 
		true, 
		roadOutput.endRoadPointVector2Data.direction
	)
end)