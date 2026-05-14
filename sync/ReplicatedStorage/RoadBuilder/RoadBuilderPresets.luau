local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RoadBuilderEnums = require(ReplicatedStorage.RoadBuilder.RoadBuilderEnums)
local MudRoad = require(script.MudRoad)

local Presets = {}

Presets.RoadTypeData = {
	[RoadBuilderEnums.RoadType.Mud] = MudRoad
}:: {[string]: RoadBuilderEnums.RoadData}

return Presets