local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local RoadBuilderCache = require(ReplicatedStorage.RoadBuilder.RoadBuilderCache)
local RoadBuilderPlayerState = require(ServerScriptService.RoadBuilderServer.RoadBuilderPlayerState)
local RoadBuilderCreation = require(ReplicatedStorage.RoadBuilder.RoadBuilderCreation)
local CreateRoadConfig = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.CreateRoadConfig)
local OverrideRoadConfig = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.OverrideRoadConfig)
local PointVector2Data = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.PointVector2Data)
local RoadConfigData = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.RoadConfigData)
local RoadCreationOutputData = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.RoadCreationOutputData)
local CreateTypeEnums = require(ReplicatedStorage.RoadBuilder.RoadBuilderEnums.CreateTypeEnums)
local RoadVariantEnums = require(ReplicatedStorage.RoadBuilder.RoadBuilderEnums.RoadVariantEnums)
local RoadBuilderEvents = require(ReplicatedStorage.RoadBuilder.RoadBuilderEvents)
local context = require(ReplicatedStorage.SharedPackages.Vide.context)
local VectorUtils = require(ReplicatedStorage.SharedUtils.VectorUtils)

--[[
    load player state for road building system
]]
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        RoadBuilderPlayerState.NewPlayerState(player)
    end)
end)

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

RoadBuilderEvents.RequestRoadData.OnServerInvoke = function(_, roadPointPosition: Vector3)
    --TODO: make these use the function lol
	return RoadBuilderCache.RoadPointCacheList[RoadBuilderCache.Vector3ToRoadInstanceCacheList[roadPointPosition]]
end

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

    --[[
        TODO: FINALIZE AN OVERRIDING FUNCTION FOR THIS, like an overarching function 
        in RoadBuilderCache to clear out all traces of an old roadpoint 
    ]]
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
    RoadBuilderCache.RoadPointCacheList[previousRoadPoint] = nil
    RoadBuilderCache.Vector3ToRoadInstanceCacheList[previousRoadPoint.Position] = nil
end

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
                CreateTypeEnums.Default,
                workspace
            ),

            fromPositionVector2Data,
            true
        )

    -- step 1: extend from origin road
	else
        roadOutput = RoadBuilderCreation.CreateExtensionRoad(
            RoadConfigData(
                roadType, 
                CreateTypeEnums.Default,
                workspace
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