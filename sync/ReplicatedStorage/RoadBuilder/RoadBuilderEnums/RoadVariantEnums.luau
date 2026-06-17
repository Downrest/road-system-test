export type RoadPointVariant = "RoadPoint"
export type RoadExtensionVariant = "RoadExtension"
export type RoadVariantEnums = RoadPointVariant | RoadExtensionVariant

type RoadVariantEnumsTable = {
    RoadPoint: RoadPointVariant;
    RoadExtension: RoadExtensionVariant;
}

return {
    RoadPoint = "RoadPoint";
    RoadExtension = "RoadExtension";
}:: RoadVariantEnumsTable