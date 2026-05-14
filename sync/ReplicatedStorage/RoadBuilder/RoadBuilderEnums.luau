local Enums = {}

--[[
	ROAD DATA
]]
Enums.RoadType = {
	Gravel = "Gravel";
	Mud = "Mud";
};

Enums.RoadPointTag = "SelectableRoad"

export type RoadType = "Gravel" | "Mud"

export type RoadData = {
    Name: string;
    RoadType: string;
    Gui: {
        IconImageId: string;
    };
}

--[[
	ROAD BUILDER
]]

export type PointVector2Data = {
	position: Vector2,
	direction: Vector2,
	yLevel: number
}

export type RoadConfig = {
	roadType: string, 
	createType: string,
	roadParent: Instance
}

export type SelectedRoadData = {
	instance: BasePart,
	pointVector2Data: PointVector2Data
}

--[[
	CREATE TYPES
]]

Enums.CreateType = {
	Visualize = "Visualize";
	Default = "Default";
};

return Enums