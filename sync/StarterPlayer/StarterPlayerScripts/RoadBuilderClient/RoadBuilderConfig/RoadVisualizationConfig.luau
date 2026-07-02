local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DefaultCreateType = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.CreatePropertyWrappers.DefaultCreateType)
local VisualizeCreateType = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.CreatePropertyWrappers.VisualizeCreateType)

local visualizationAssetContainer = workspace.CurrentCamera

local function newHighlightColorProperties(
    fillColor: Color3,
    fillTransparency: number,
    outlineColor: Color3,
    outlineTransparency: number
)
    return {
        FillColor = fillColor;
        FillTransparency = fillTransparency;
        OutlineColor = outlineColor;
        OutlineTransparency = outlineTransparency;
    }
end

return {
    HIGHLIGHT_ROAD_POINT_LIMIT = 150;

    HIGHLIGHT_ROAD_COLORS = {
        default = newHighlightColorProperties(
            Color3.new(0, 1, 0),
            .95,
            Color3.new(0, 1, 0),
            .45
        );
    };
    HIGHLIGHT_ROAD_POINT_COLORS = {
        nothing = newHighlightColorProperties(
            Color3.new(0, 1, 0),
            .95,
            Color3.new(0, 1, 0),
            .25
        );
        dependentPoint = newHighlightColorProperties(
            Color3.new(0.831373, 1, 0),
            .75,
            Color3.new(0.831373, 1, 0),
            .5
        );
        endPoint = newHighlightColorProperties(
            Color3.new(0, 1, 0),
            .65,
            Color3.new(0, 1, 0),
            .25
        );
    };
    VISUALIZATION_ASSET_CONTAINER = visualizationAssetContainer;
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
                    },
                    visualizationAssetContainer
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
            },
            visualizationAssetContainer
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
            },
            visualizationAssetContainer
        );
    };

    RENDER_THROTTLE_PER_ROAD_DISTANCE = {
        throttleSeconds = .5;
        roadDistance = 2000;
    };

    -- multiplier for vertical remake, just there to make it feel better
    VERTICAL_REMAKE_MULTIPLIER = 2;
}