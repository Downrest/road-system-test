local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VisualizeCreateType = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.CreateTypeWrappers.VisualizeCreateType)

return {
	VISUALIZER_ROAD_CREATE_TYPES = {
        default = VisualizeCreateType(
            {
                Transparency = .5;
            },
            {
                Transparency = .75;
            }
        );
        remake = VisualizeCreateType(
            {
                Transparency = .5;
                Color = Color3.new(0.282353, 0.313725, 0.870588);
            },
            {
                Transparency = .75;
                Color = Color3.new(0.282353, 0.313725, 0.870588);
            }
        );
        error = VisualizeCreateType(
            {
                Transparency = .5;
                Color = Color3.new(0.968627, 0.14902, 0.14902);
            },
            {
                Transparency = .75;
                Color = Color3.new(0.968627, 0.14902, 0.14902);
            }
        );
    };

    RENDER_THROTTLE_PER_ROAD_DISTANCE = {
        throttleSeconds = .05;
        roadverticalDistance = 600;
    };
}