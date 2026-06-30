local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RoadBuilderCache = require(ReplicatedStorage.RoadBuilder.RoadBuilderCache)
local RoadCreationConfig = require(ReplicatedStorage.RoadBuilder.RoadBuilderConfig.RoadCreationConfig)
local CreateRoadConfig = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.CreateRoadWrappers.CreateRoadConfig)
local CreateVariantEnums = require(ReplicatedStorage.RoadBuilder.RoadBuilderEnums.CreateVariantEnums)
local RoadPointCacheTypeEnums = require(ReplicatedStorage.RoadBuilder.RoadBuilderEnums.RoadPointCacheTypeEnums)
local RoadBuilderCurveUtils = require(ReplicatedStorage.RoadBuilder.RoadBuilderUtils.RoadBuilderCurveUtils)
local MathGeneral = require(ReplicatedStorage.SharedUtils.MathUtils.MathGeneral)
local VectorUtils = require(ReplicatedStorage.SharedUtils.VectorUtils)

local SelectionValidator = {}

--[[
	Validates an extension road (in other words, the curve) to see if the delta angle from origin to first bezier point approaching goal exceeds a maximum angle.

	Maximum angle defaults to `CURVE_ANGLE_MAXIMUM`, but you can override with `overrideMaximumAngle`.
]]
local function validateCurveAngle(
	roadConfig: CreateRoadConfig.CreateRoadConfig,
	remakeGoalPosition: Vector3?
): boolean
	local remakeGoalPositionVector2 = remakeGoalPosition and VectorUtils.Vector2FromVector3(remakeGoalPosition)

	local originVector2Data, isDefaultDirection = RoadCreationConfig.ApplyDefaultDirectionToVector2Data(
		roadConfig.fromPositionVector2Data
	)
	local originPosition = originVector2Data.position
	local originDirection = remakeGoalPositionVector2
		and (remakeGoalPositionVector2 - originPosition).Unit 
		or originVector2Data.direction

	local goalVector2Data = roadConfig.toPositionVector2Data
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

function SelectionValidator.IsValidRoadPoint(
	roadPoint: BasePart,
	checkIfEndPoint: boolean?
): (boolean, boolean?)
	local roadPointCache = RoadBuilderCache.GetRoadPointCache(roadPoint)

    return 
		(roadPointCache ~= nil),
	
		checkIfEndPoint 
		and roadPointCache
		and (roadPointCache.roadPointCacheType == RoadPointCacheTypeEnums.EndPoint)
end

function SelectionValidator.ValidateRoadRequest(
	createRoadConfig: CreateRoadConfig.CreateRoadConfig,
	remakeGoalPosition: Vector3? -- implies that its a remake
): boolean
    local wasVerified = true

    if RoadCreationConfig.ROAD_VALIDATION_RULES.isRoadAngleLimited then
        if 
            createRoadConfig.createVariant == CreateVariantEnums.RoadExtension
			--[[
				direction is equal to either nil or `DEFAULT_ROAD_POINT_AXIS` for "precusor" roadpoints
			]]
			and createRoadConfig.fromPositionVector2Data.direction ~= RoadCreationConfig.DEFAULT_ROAD_POINT_AXIS
            and not validateCurveAngle(
                createRoadConfig,
				remakeGoalPosition
            )
        then
			wasVerified = false
            return wasVerified
        end
    end

    wasVerified = true
    return wasVerified
end

return SelectionValidator
