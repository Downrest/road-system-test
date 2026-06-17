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
    --TODO: LOWKEY MOVE THESE TO BE PURELY ON THE CLIENT, PRESETS SHOULD NOT BE RESPONSIBLE FOR THIS
    -- make roadbuildercreation take in a datawrapper purely for visualizeproperties as a parameter
    VisualizeProperties = {
        road = {
            CanQuery = false;
            CanCollide = false;
			Transparency = 0;
		};
		roadPoint = {
            CanQuery = false;
            CanCollide = false;
			Transparency = 0;
		};
    }
}