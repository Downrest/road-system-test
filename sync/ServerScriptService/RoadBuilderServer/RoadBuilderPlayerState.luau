local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RoadBuilderCreation = require(ReplicatedStorage.RoadBuilder.RoadBuilderCreation)

local State = {}

export type PlayerBuildState = {
    SelectedRoad: RoadBuilderCreation.CreatedRoadPointData;
}
State.PlayerBuildStates = {}:: {[Player]: PlayerBuildState}

--[[
    Returns a reference to the player state table, assuming it exists.
]]
function State.GetPlayerState(player: Player): PlayerBuildState
    return State.PlayerBuildStates[player] or error(`No player state has been found with {player.Name}`)
end

--[[
    Creates a player state table.
]]
function State.NewPlayerState(player: Player)
    State.PlayerBuildStates[player] = {
        SelectedRoad = nil;
    }
end

return State
