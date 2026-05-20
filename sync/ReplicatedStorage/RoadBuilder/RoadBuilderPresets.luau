local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RoadTypeEnums = require(ReplicatedStorage.RoadBuilder.RoadBuilderEnums.RoadTypeEnums)
local MudRoad = require(script.MudRoad)
local GravelRoad = require(script.GravelRoad)

local Presets = {}


--TODO ADD A ADD A PRESETS TYPE
Presets.RoadTypeData = {
    [RoadTypeEnums.Mud] = MudRoad;
    [RoadTypeEnums.Gravel] = GravelRoad;
}

return Presets