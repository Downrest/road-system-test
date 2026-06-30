local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RoadTypeEnums = require(ReplicatedStorage.RoadBuilder.RoadBuilderEnums.RoadTypeEnums)

export type RoadPresetData = {
	Name: string;
	RoadType: RoadTypeEnums.RoadTypeEnums;
	Assets: {
		RoadPoint: BasePart;
		Road: BasePart;
	};
	Gui: {
		IconImageId: string;
	};
}

return function(
	name: string,
	roadType: RoadTypeEnums.RoadTypeEnums,
	
	roadPointAsset: BasePart,
	roadAsset: BasePart,

	guiIconImageId: string
): RoadPresetData
	return {
		Name = name;
		RoadType = roadType;
		Assets = {
			RoadPoint = roadPointAsset;
			Road = roadAsset;
		};
		Gui = {
			IconImageId = guiIconImageId;
		};
	}
end
