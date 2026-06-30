local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RoadTypeEnums = require(ReplicatedStorage.RoadBuilder.RoadBuilderEnums.RoadTypeEnums)
local RoadBuilderAssetGetter = require(ReplicatedStorage.RoadBuilder.RoadBuilderAssetGetter)
local RoadPresetData = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.RoadPresetData)

local roadType = RoadTypeEnums.Gravel

return RoadPresetData(
    roadType,
    roadType,

    RoadBuilderAssetGetter.roadAssets[roadType].roadPoint,
    RoadBuilderAssetGetter.roadAssets[roadType].road,

    "rbxassetid://12268609102"
)