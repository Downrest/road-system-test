local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RoadTypeEnums = require(ReplicatedStorage.RoadBuilder.RoadBuilderEnums.RoadTypeEnums)
local RoadBuilderAssetGetter = require(ReplicatedStorage.RoadBuilder.RoadBuilderAssetGetter)

local roadType = RoadTypeEnums.Gravel

return {
    Name = roadType;
    RoadType = roadType;
    Assets = {
        Road = RoadBuilderAssetGetter.roadAssets[roadType].road;
        RoadPoint = RoadBuilderAssetGetter.roadAssets[roadType].roadPoint;
    };
    Gui = {
        IconImageId = "rbxassetid://12268609102";
    };
}