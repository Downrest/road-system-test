export type RoadPointVariant = "RoadPoint"
export type RoadExtensionVariant = "RoadExtension"
export type CreateVariantEnums = RoadPointVariant | RoadExtensionVariant

type CreateVariantEnumsTable = {
    RoadPoint: RoadPointVariant;
    RoadExtension: RoadExtensionVariant;
}

return {
    RoadPoint = "RoadPoint";
    RoadExtension = "RoadExtension";
}:: CreateVariantEnumsTable