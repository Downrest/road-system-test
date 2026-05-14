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

export type RoadType = "Gravel" | "Mud"

return {
	RoadType = {
		Gravel = "Gravel";
		Mud = "Mud";
	};

	CreateType = {
		Visualize = "Visualize";
		Default = "Default";
	};

	Tags = {
		SelectableRoad = "SelectableRoad";
	};
}