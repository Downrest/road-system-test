export type GravelType = "Gravel"
export type MudType = "Mud"
export type RoadTypeEnums = GravelType | MudType

type RoadTypeEnumsTable = {
	Gravel: GravelType;
	Mud: MudType;
};

return {
	Gravel = "Gravel";
	Mud = "Mud";
}:: RoadTypeEnumsTable