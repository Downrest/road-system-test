local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CreateTypeEnums = require(ReplicatedStorage.RoadBuilder.RoadBuilderEnums.CreateTypeEnums)

type DefaultProperties = {
	CanCollide: boolean;
	CanQuery: boolean;
	Transparency: number;
}
export type DefaultCreateType = {
	tag: CreateTypeEnums.DefaultType;
	visualizedProperties: {
		roadPoint: DefaultProperties;
		road: DefaultProperties;
	}
}

return function(): DefaultCreateType
    return {
		tag = CreateTypeEnums.Default;
		visualizedProperties = {
			roadPoint = {
				CanCollide = false;
				CanQuery = true;
				Transparency = 0;
			};
			road = {
				CanCollide = false;
				CanQuery = true;
				Transparency = 0;
			};
		}
    };
end
