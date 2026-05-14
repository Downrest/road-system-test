local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RoadBuilderAssetGetter = require(ReplicatedStorage.RoadBuilder.RoadBuilderAssetGetter)
local RoadBuilderEnums = require(ReplicatedStorage.RoadBuilder.RoadBuilderEnums)

local roadType = RoadBuilderEnums.RoadType.Mud

return {
    Name = roadType;
    RoadType = roadType;
    Assets = {
        Road = RoadBuilderAssetGetter.GetRoadFromType(roadType);
        RoadPoint = RoadBuilderAssetGetter.GetRoadPointFromType(roadType);
    };
    Gui = {
        IconImageId = "rbxassetid://12268609102";
    };
}