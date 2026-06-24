local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CreateTypeEnums = require(ReplicatedStorage.RoadBuilder.RoadBuilderEnums.CreateTypeEnums)

export type VisualizeCreateType<
    roadPointProperties = {[string]: any}, 
    roadProperties = {[string]: any}
> = {
    tag: CreateTypeEnums.VisualizeType;
    visualizedProperties: VisualizedProperties<roadPointProperties, roadProperties>;
}

type VisualizedProperties<
    roadPointProperties = {[string]: any}, 
    roadProperties = {[string]: any}
> = {
    roadPoint: roadPointProperties;
    road: roadProperties;
}

return function<roadPointProperties, roadProperties>(
    roadPointProperties: {[string]: any},
    roadProperties: {[string]: any}
): VisualizeCreateType<roadPointProperties, roadProperties>
    return {
        tag = CreateTypeEnums.Visualize;
        visualizedProperties = {
            roadPoint = roadPointProperties;
            road = roadProperties;
        };
    }
end
