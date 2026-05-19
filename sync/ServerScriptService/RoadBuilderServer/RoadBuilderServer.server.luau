local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local RoadBuilderPlayerState = require(ServerScriptService.RoadBuilderServer.RoadBuilderPlayerState)
local RoadBuilderCreation = require(ReplicatedStorage.RoadBuilder.RoadBuilderCreation)
local PointVector2Data = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.PointVector2Data)
local RoadConfigData = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.RoadConfigData)
local RoadCreationOutputData = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.RoadCreationOutputData)
local CreateTypeEnums = require(ReplicatedStorage.RoadBuilder.RoadBuilderEnums.CreateTypeEnums)
local RoadVariantEnums = require(ReplicatedStorage.RoadBuilder.RoadBuilderEnums.RoadVariantEnums)
local RoadBuilderEvents = require(ReplicatedStorage.RoadBuilder.RoadBuilderEvents)

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
    fromPositionVector2Data: PointVector2Data.type,
    toPositionVector2Data: PointVector2Data.type?
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

--[[
    client requests road creation assuming there is available road selection data which is either
        provided via selectedRoadInstance
        PROVIDED
    
    automatically sets playerState.SelectedRoadPoint to
    the newly created road point (or if its an extension road, the very last road point)
]]
RoadBuilderEvents.CreateRoadRequest.OnServerEvent:Connect(function(
    player: Player, 
    roadType: string,
    roadVariant: string,
    fromPositionVector2Data: PointVector2Data.type,
    toPositionVector2Data: PointVector2Data.type? -- only available if making road extensions
)
    assertRoadVariant(roadVariant, fromPositionVector2Data, toPositionVector2Data)

    local roadOutput: RoadCreationOutputData.type
    warn(fromPositionVector2Data.direction)
    
    -- step 0: create origin road
    if roadVariant == RoadVariantEnums.RoadPoint then
         roadOutput = RoadBuilderCreation.CreateOriginRoad(
            RoadConfigData(
                roadType, 
                CreateTypeEnums.Default,
                workspace
            ),

            fromPositionVector2Data
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
	-- RoadBuilderEvents.CreateRoadRequest:FireClient(
	-- 	player, 
	-- 	true, 
	-- 	roadOutput.endRoadPointInstance,
    --     roadOutput.endRoadPointVector2
	-- )
end)
