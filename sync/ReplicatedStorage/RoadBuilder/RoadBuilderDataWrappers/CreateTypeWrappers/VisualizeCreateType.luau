local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CreateTypeEnums = require(ReplicatedStorage.RoadBuilder.RoadBuilderEnums.CreateTypeEnums)

export type VisualizeCreateType = {
    tag: CreateTypeEnums.VisualizeType;
    visualizedProperties: VisualizedProperties;
}

type VisualizedProperties = {
    roadPoint: {[string]: any};
    road: {[string]: any};
}

return function(
    roadPointProperties: {[string]: any},
    roadProperties: {[string]: any}
): VisualizeCreateType
    return {
        tag = CreateTypeEnums.Visualize;
        visualizedProperties = {
            roadPoint = roadPointProperties;
            road = roadProperties;
        };
    }
end
