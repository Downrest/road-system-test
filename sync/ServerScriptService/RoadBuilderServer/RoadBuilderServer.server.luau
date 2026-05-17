local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local RoadBuilderPlayerState = require(ServerScriptService.RoadBuilderServer.RoadBuilderPlayerState)
local RoadBuilderCreation = require(ReplicatedStorage.RoadBuilder.RoadBuilderCreation)
local PointVector2Data = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.PointVector2Data)
local RoadConfigData = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.RoadConfigData)
local CreateTypeEnums = require(ReplicatedStorage.RoadBuilder.RoadBuilderEnums.CreateTypeEnums)
local RoadBuilderEvents = require(ReplicatedStorage.RoadBuilder.RoadBuilderEvents)

--[[
    load player state for road building system
]]
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        RoadBuilderPlayerState.NewPlayerState(player)
    end)
end)

-- --[[
--     client requests to set road selection data
-- ]]
-- RoadBuilderEvents.NewSelectedRoadRequest.OnServerEvent:Connect(function(
--     player,
--     selectedRoadInstance: BasePart
-- )
--     --TODO do sanity checks

--     local playerState = RoadBuilderPlayerState.GetPlayerState(player)
--     playerState.SelectedRoad = selectedRoadInstance
-- end)

-- --[[
--     client requests to clear road selection data
-- ]]
-- RoadBuilderEvents.ClearSelectedRoadRequest.OnServerEvent:Connect(function(player)
--     local playerState = RoadBuilderPlayerState.GetPlayerState(player)
--     playerState.SelectedRoad = nil
-- end)

--[[
    client requests road creation assuming there is available road selection data which is either
        provided via selectedRoadInstance
        PROVIDED
    
    automatically sets playerState.SelectedRoad to
    the newly created road point (or if its an extension road, the very last road point)
]]
RoadBuilderEvents.CreateRoadRequest.OnServerEvent:Connect(function(
    player: Player, 
    mousePosition: Vector3,
    roadType: string
)
    --TODO do sanity checks

    local playerState = RoadBuilderPlayerState.PlayerBuildStates[player]
    local playerSelectedRoad = playerState.SelectedRoad

    local mouseVector2Data = PointVector2Data(mousePosition)

    -- step 0: create origin road
    if not playerSelectedRoad then
        local originRoadOutput = RoadBuilderCreation.CreateOriginRoad(
            RoadConfigData(
                roadType, 
                CreateTypeEnums.Default,
                workspace
            ),

            mouseVector2Data
        )
        playerState.SelectedRoad = originRoadOutput.endRoadInstance

    -- step 1: extend from origin road
	else
        local extensionRoadOutput = RoadBuilderCreation.CreateExtensionRoad(
            RoadConfigData(
                roadType, 
                CreateTypeEnums.Default,
                workspace
            ),

            playerSelectedRoad.pointVector2Data, 
            mouseVector2Data
        )
        playerState.SelectedRoad = extensionRoadOutput.endRoadInstance
	end
	
    -- toggles client's road visualization (either success or failure to create road)
	RoadBuilderEvents.CreateRoadRequest:FireClient(
		player, 
		true, 
		playerState.SelectedRoad
	)
end)
