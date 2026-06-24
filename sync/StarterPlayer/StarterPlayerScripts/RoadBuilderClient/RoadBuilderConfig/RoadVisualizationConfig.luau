local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DefaultCreateType = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.CreateTypeWrappers.DefaultCreateType)
local VisualizeCreateType = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.CreateTypeWrappers.VisualizeCreateType)

return {
    VISUALIZATION_ASSET_CONTAINER = workspace.Camera;
	VISUALIZER_ROAD_CREATE_TYPES = {
        --[[
            a function because of necessary parameter(s):
                isFullyRendered implies it isnt a simulated road
        ]]
        default = function(isFullyRendered: boolean?): VisualizeCreateType.VisualizeCreateType<
            {CanCollide: boolean, CanQuery: boolean, Transparency: number},
            {CanCollide: boolean, CanQuery: boolean, Transparency: number}
        >
            if isFullyRendered then
                return DefaultCreateType()
            else
                return VisualizeCreateType(
                    {
                        CanCollide = false;
                        CanQuery = false;
                        Transparency = 0;
                    },
                    {
                        CanCollide = false;
                        CanQuery = false;
                        Transparency = 0;
                    }
                );
            end
        end;
        remake = VisualizeCreateType<<
            {CanCollide: boolean, CanQuery: boolean, Transparency: number, Color: Color3},
            {CanCollide: boolean, CanQuery: boolean, Transparency: number, Color: Color3}
        >>(
			{
				CanCollide = false;
				CanQuery = false;
                Transparency = .15;
                Color = Color3.new(0.282353, 0.313725, 0.870588);
            },
			{
				CanCollide = false;
				CanQuery = false;
                Transparency = .35;
                Color = Color3.new(0.282353, 0.313725, 0.870588);
            }
        );
        error = VisualizeCreateType<<
            {CanCollide: boolean, CanQuery: boolean, Transparency: number, Color: Color3},
            {CanCollide: boolean, CanQuery: boolean, Transparency: number, Color: Color3}
        >>(
			{
				CanCollide = false;
				CanQuery = false;
                Transparency = .15;
                Color = Color3.new(0.968627, 0.14902, 0.14902);
            },
			{
				CanCollide = false;
				CanQuery = false;
                Transparency = .35;
                Color = Color3.new(0.968627, 0.14902, 0.14902);
            }
        );
    };

    RENDER_THROTTLE_PER_ROAD_DISTANCE = {
        throttleSeconds = .05;
        roadverticalDistance = 600;
    };
}