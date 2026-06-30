local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RoadBuilderCache = require(ReplicatedStorage.RoadBuilder.RoadBuilderCache)
local RoadBuilderCreation = require(ReplicatedStorage.RoadBuilder.RoadBuilderCreation)
local CreateRoadConfig = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.CreateRoadWrappers.CreateRoadConfig)
local DefaultCreateType = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.CreatePropertyWrappers.DefaultCreateType)
local PointVector2Data = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.PointVector2Data)
local RoadConfigData = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.RoadConfigData)
local CreateVariantEnums = require(ReplicatedStorage.RoadBuilder.RoadBuilderEnums.CreateVariantEnums)
local RoadBuilderEvents = require(ReplicatedStorage.RoadBuilder.RoadBuilderEvents)

local function assertCreateVariant(
    createVariant: string,
    fromPositionVector2Data: PointVector2Data.PointVector2Data,
    toPositionVector2Data: PointVector2Data.PointVector2Data?
)
    if createVariant == CreateVariantEnums.RoadPoint then
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

--[[
    load existing road cache to new players
]]
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
    local createVariant = createRoadConfig.createVariant
    local overrideRoadConfig = createRoadConfig.overrideRoadConfig
    local fromPositionVector2Data = createRoadConfig.fromPositionVector2Data
    local toPositionVector2Data = createRoadConfig.toPositionVector2Data

    assertCreateVariant(createVariant, fromPositionVector2Data, toPositionVector2Data)

    -- clear previous road (if applicable)
    -- overridePreviousRoad(overrideRoadConfig)

    -- step 0: create origin road
    if createVariant == CreateVariantEnums.RoadPoint then
        RoadBuilderCreation.CreateOriginRoadPoint(
            RoadConfigData(
                roadType, 
                DefaultCreateType(),
                overrideRoadConfig
            ),

            fromPositionVector2Data,
            true
        )

    -- step 1: extend from origin road
	else
        RoadBuilderCreation.CreateExtensionRoad(
            RoadConfigData(
                roadType, 
                DefaultCreateType(),
                overrideRoadConfig
            ),

            fromPositionVector2Data, 
            toPositionVector2Data
        )
	end
end)