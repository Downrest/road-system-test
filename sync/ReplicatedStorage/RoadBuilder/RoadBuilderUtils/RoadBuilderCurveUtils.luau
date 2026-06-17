local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RoadCreationConfig = require(ReplicatedStorage.RoadBuilder.RoadBuilderConfig.RoadCreationConfig)
local MathCurves = require(ReplicatedStorage.SharedUtils.MathUtils.MathCurves)
local CurveUtils = {}

local function curveControlPointsFromCurveLerpValues(
	originValue: number, 
	originDirection: number,
	goalValue: number, 
	originToGoalDistance: number,
	lerpValues: {number}
): number
	local curvePoints = {}

	local originDirectionLerpValues = {
		originValue,
		originValue + (originDirection * (originToGoalDistance / 2))
	}
	local toGoalLerpValues = {
		originValue + (originDirection * (originToGoalDistance / 2)),
		goalValue
	}

	for _, lerpValue in lerpValues do
		table.insert(
			curvePoints,
			math.lerp(
				math.lerp(
					originDirectionLerpValues[1],
					originDirectionLerpValues[2],
					lerpValue
				),
				math.lerp(
					toGoalLerpValues[1],
					toGoalLerpValues[2],
					lerpValue
				),
				lerpValue
			)
		)
	end

	return table.unpack(curvePoints)
end

--[[
	generally how this works is we have two directions 
		1: direction towards originDirection (previous direction of road point)
		2: direction towards goalPosition (mouse position)

	we use `CURVE_LERP_VALUES` to act as control points for the bezier curve using these two directions
	to create a curve that prioritizes originDirection before slowly approaching goalPosition

	in `CURVE_LERP_VALUES`, 0 opts for originDirection while 1 opts for goalPosition
]]
function CurveUtils.GetCurveVector2(
	originPosition: Vector2,
	originDirection: Vector2,
	goalPosition: Vector2
)
	local goalToOriginLength = Vector2.new(
		(goalPosition.X - originPosition.X),
		(goalPosition.Y - originPosition.Y)
	)
	local goalToOriginDotProduct = originDirection.Unit:Dot(goalToOriginLength.Unit)
	local goalToOriginDistance = (goalToOriginLength.Magnitude * goalToOriginDotProduct)

	return {
		get = function(t): Vector2
			local curveX = MathCurves.NthBezierCurve(
				t,	

				curveControlPointsFromCurveLerpValues(
					originPosition.X,
					originDirection.X,
					goalPosition.X,
					goalToOriginDistance,
					RoadCreationConfig.ROAD_CURVE_LERP_VALUES
				)
			)
			local curveY = MathCurves.NthBezierCurve(
				t,	

				curveControlPointsFromCurveLerpValues(
					originPosition.Y,
					originDirection.Y,
					goalPosition.Y,
					goalToOriginDistance,
					RoadCreationConfig.ROAD_CURVE_LERP_VALUES
				)
			)

			return Vector2.new(curveX, curveY)
		end;
	}
end

return CurveUtils
