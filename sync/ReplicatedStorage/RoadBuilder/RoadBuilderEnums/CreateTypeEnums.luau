export type VisualizeType = "Visualize"
export type DefaultType = "Default"
export type CreateTypeEnums = VisualizeType | DefaultType

type CreateTypeEnumsTable = {
	Visualize: VisualizeType;
	Default: DefaultType
}

return {
	Visualize = "Visualize";
	Default = "Default";
}:: CreateTypeEnumsTable
