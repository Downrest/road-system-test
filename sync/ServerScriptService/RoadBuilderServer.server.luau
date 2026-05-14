local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RoadBuilderCreation = require(ReplicatedStorage.RoadBuilderShared.RoadBuilderCreation)
local RoadBuilderEnums = require(ReplicatedStorage.RoadBuilderShared.RoadBuilderEnums)
local RoadBuilderPlayerState = require(script.RoadBuilderPlayerState)
local RoadBuilderEvents = require(ReplicatedStorage.RoadBuilderShared.RoadBuilderEvents)

--[[
    load player state for road building system
]]
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        RoadBuilderPlayerState.NewPlayerState(player)
    end)
end)

--[[
    client requests road creation
]]
RoadBuilderEvents.CreateRoad.OnServerEvent:Connect(function(
    player: Player, 
    mouseRay: Ray, -- raycasts are ran in the server, mouseRay merely carries mouse data
    roadType: string
)
    --TODO do sanity checks

    local mouseRaycast = workspace:Raycast(mouseRay.Origin, mouseRay.Direction * 1000)
    assert(mouseRaycast, "Mouse raycast hit nothing")

    local mousePosition = mouseRaycast.Position

    local playerState = RoadBuilderPlayerState.PlayerBuildStates[player]
    local playerSelectedRoad = playerState.SelectedRoad

    local mouseVector2Data = RoadBuilderCreation.PointVector2Data(mousePosition)

    -- step 0: create origin road
    if not playerSelectedRoad then
        local originRoadData = RoadBuilderCreation.CreateOriginRoad(
            RoadBuilderCreation.RoadConfig(
                roadType, 
                RoadBuilderEnums.CreateType.Default,
                workspace
            ),

            mouseVector2Data
        )
        playerState.SelectedRoad = originRoadData

    -- step 1: extend from origin road
	else
        local extensionRoadData = RoadBuilderCreation.CreateExtensionRoad(
            RoadBuilderCreation.RoadConfig(
                roadType, 
                RoadBuilderEnums.CreateType.Default,
                workspace
            ),

            playerSelectedRoad.pointVector2Data, 
            mouseVector2Data
        )
        playerState.SelectedRoad = extensionRoadData
	end
	
    -- toggles client's road visualization (either success or failure to create road)
	RoadBuilderEvents.RenderRoad:FireClient(
		player, 
		true, 
		playerState.SelectedRoad.pointVector2Data
	)
end)
