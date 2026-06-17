local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RoadCreationConfig = require(ReplicatedStorage.RoadBuilder.RoadBuilderConfig.RoadCreationConfig)
local CreateRoadConfig = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.CreateRoadConfig)
local PointVector2Data = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.PointVector2Data)
local RoadInstanceTagEnums = require(ReplicatedStorage.RoadBuilder.RoadBuilderEnums.RoadInstanceTagEnums)
local RoadVariantEnums = require(ReplicatedStorage.RoadBuilder.RoadBuilderEnums.RoadVariantEnums)
local RoadBuilderCurveUtils = require(ReplicatedStorage.RoadBuilder.RoadBuilderUtils.RoadBuilderCurveUtils)
local MathGeneral = require(ReplicatedStorage.SharedUtils.MathUtils.MathGeneral)

local SelectionValidator = {}

--[[
	Validates an extension road (in other words, the curve) to see if the delta angle from origin to first bezier point approaching goal exceeds a maximum angle.

	Maximum angle defaults to `CURVE_ANGLE_MAXIMUM`, but you can override with `overrideMaximumAngle`.
]]
local function validateCurveAngle(
	originVector2Data: PointVector2Data.PointVector2Data,
	goalVector2Data: PointVector2Data.PointVector2Data
): boolean
	originVector2Data = RoadCreationConfig.ApplyDefaultDirectionToVector2Data(originVector2Data)

	local originPosition = originVector2Data.position
	local originDirection = originVector2Data.direction

	local goalPosition = goalVector2Data.position

	local originToGoalDistance = (originPosition - goalPosition).Magnitude
	local curveFrequency = RoadCreationConfig.ROAD_CURVE_FREQUENCY_PER_N_STUDS.frequency * (originToGoalDistance / RoadCreationConfig.ROAD_CURVE_FREQUENCY_PER_N_STUDS.nStuds)
	local maximumCurveAngle = RoadCreationConfig.ROAD_VALIDATION_VALUES.roadCurveMaximumAngle

	-- first bezier point approaching goal
	local curvePosition = RoadBuilderCurveUtils.GetCurveVector2(
		originPosition,
		originDirection,
		goalPosition
	).get((1/curveFrequency))
	local curveDirection = (curvePosition - originPosition).Unit

	local originToCurveDotAngle = MathGeneral.DotAngleBetween(originDirection, curveDirection)

	return (originToCurveDotAngle <= maximumCurveAngle)
end

function SelectionValidator.IsValidRoadPoint(instance: BasePart): boolean
    return instance and instance:HasTag(RoadInstanceTagEnums.RoadPoint) or false
end

function SelectionValidator.ValidateRoadRequest(createRoadConfig: CreateRoadConfig.CreateRoadConfig): boolean
    local wasVerified = false

    if RoadCreationConfig.ROAD_VALIDATION_RULES.isRoadAngleLimited then
        if 
            createRoadConfig.roadVariant == RoadVariantEnums.RoadExtension
            and not validateCurveAngle(
                createRoadConfig.fromPositionVector2Data,
                createRoadConfig.toPositionVector2Data
            ) 
        then
			warn(`TRYING TO VALIDATE! {createRoadConfig.fromPositionVector2Data.direction}`)
            return wasVerified
        end
    end

    wasVerified = true
    return wasVerified
end

return SelectionValidator
