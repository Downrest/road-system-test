local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PointVector2Data = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.PointVector2Data)
local MathEasing = require(ReplicatedStorage.SharedUtils.MathUtils.MathEasing)

local roadinstancesFolder = workspace.RoadInstances
local roadPointFolder: Folder = roadinstancesFolder.RoadPoint
local roadFolder = roadinstancesFolder.Road

local Config = {
	--[[
		CREATION
	]]

	-- limits road points from getting closer in distance between either origin or goal beyond this value
	ROAD_CURVE_EDGE_LIMIT = 2;
	ROAD_CURVE_T_EASING = {
		horizontal = MathEasing.EaseInSine;
		vertical = MathEasing.EaseInOutSine;
	};
	--[[
		control points for bezier curve ranging [0, 1], depicts the expected road curve
	]]
	ROAD_CURVE_LERP_VALUES = {
		MathEasing.GetEasingPointsTuple(10, MathEasing.EaseInOutSine)
	};
	-- amount of road points per nStuds is created in the entire road extension curve
	ROAD_CURVE_FREQUENCY_PER_N_STUDS = {
		frequency = 1,
		nStuds = 2.5
	};
	DEFAULT_ROAD_POINT_AXIS = Vector2.xAxis;

	--TODO: UHHH THIS CHANGE ISNT REFLECTED ON SOME CODE YET
	ROAD_PARENTS = {
		roadPoint = roadPointFolder;
		road = roadFolder;
	};

	--[[
		VALIDATION
	]]

	ROAD_VALIDATION_VALUES = {
		roadCurveMaximumAngle = 15;
	};
	ROAD_VALIDATION_RULES = {
		isRoadAngleLimited = true;
	};
}

function Config.ApplyDefaultDirectionToVector2Data(pointVector2Data: PointVector2Data.PointVector2Data): PointVector2Data.PointVector2Data
	if not pointVector2Data or pointVector2Data.direction then
		return pointVector2Data
	end

	-- localizing the avoid any overwrites with the passed PointVector2Data
	local pointVector2DataWithDir = table.clone(pointVector2Data)
	pointVector2DataWithDir.direction = Config.DEFAULT_ROAD_POINT_AXIS
	
	return pointVector2DataWithDir
end

return Config