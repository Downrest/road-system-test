local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CreateTypeEnums = require(ReplicatedStorage.RoadBuilder.RoadBuilderEnums.CreateTypeEnums)

export type VisualizeCreateType<
    roadPointProperties = {[string]: any}, 
    roadProperties = {[string]: any}
> = {
    tag: CreateTypeEnums.VisualizeType;
    visualizedProperties: {
        roadPoint: roadPointProperties;
        road: roadProperties;
    };
    parent: Instance;
}

return function<roadPointProperties, roadProperties>(
    roadPointProperties: {[string]: any},
    roadProperties: {[string]: any},
    roadParent: Instance
): VisualizeCreateType<roadPointProperties, roadProperties>
    return {
        tag = CreateTypeEnums.Visualize;
        parent = roadParent;
        visualizedProperties = {
            roadPoint = roadPointProperties;
            road = roadProperties;
        };
    }
end
