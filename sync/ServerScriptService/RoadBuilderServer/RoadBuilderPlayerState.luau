local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RoadBuilderEnums = require(ReplicatedStorage.RoadBuilder.RoadBuilderEnums)

local State = {}

export type PlayerBuildStates = {
    [Player]: {
        SelectedRoad: RoadBuilderEnums.SelectedRoadData;
    }
}

State.PlayerBuildStates = {}:: PlayerBuildStates

function State.NewPlayerState(player: Player)
    State.PlayerBuildStates[player] = {
        SelectedRoad = nil;
    }
end

return State
