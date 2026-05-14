local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RoadBuilderAssetGetter = require(ReplicatedStorage.RoadBuilder.RoadBuilderAssetGetter)
local RoadBuilderEnums = require(ReplicatedStorage.RoadBuilder.RoadBuilderEnums)
local MathCurves = require(ReplicatedStorage.SharedUtils.MathUtils.MathCurves)
local MathEasing = require(ReplicatedStorage.SharedUtils.MathUtils.MathEasing)
local MathGeneral = require(ReplicatedStorage.SharedUtils.MathUtils.MathGeneral)

local Creation = {}

--// CONFIGURATION

local CURVE_FREQUENCY_PER_N_STUDS = {
	frequency = 1,
	nStuds = 5
}
--[[
	control points for bezier curve ranging [0, 1], depicts the expected road curve
]]
local CURVE_LERP_VALUES = {
	MathEasing.GetEasingPointsTuple(10, MathEasing.EaseInCirc)
}
local CURVE_ANGLE_MAXIMUM = 45

local DEFAULT_ROAD_DIRECTION = Vector2.xAxis
local ROAD_ANGLE_CORRECTION = math.pi/2
local ASSETS = {
	road = {
		[RoadBuilderEnums.RoadType.Gravel] = RoadBuilderAssetGetter.GetRoadFromType(RoadBuilderEnums.RoadType.Gravel);
		[RoadBuilderEnums.RoadType.Mud] = RoadBuilderAssetGetter.GetRoadFromType(RoadBuilderEnums.RoadType.Mud);
	};
	roadPoint = {
		[RoadBuilderEnums.RoadType.Gravel] = RoadBuilderAssetGetter.GetRoadPointFromType(RoadBuilderEnums.RoadType.Gravel);
		[RoadBuilderEnums.RoadType.Mud] = RoadBuilderAssetGetter.GetRoadPointFromType(RoadBuilderEnums.RoadType.Mud);
	};
}

local CREATE_TYPE_TO_PART_PROPERTIES = {
	[RoadBuilderEnums.CreateType.Visualize] = {
		road = {
			Transparency = .8;
		};
		roadPoint = {
			Transparency = .5;
		};
	};
}

--// INTERNAL

local function applyArrayToProperties(instance: Instance, properties: {any})
	for propertyName, propertyValue in properties do
		pcall(function()
			instance[propertyName] = propertyValue
		end)	
	end
end

local function vector2FromVector3(vector3: Vector3): Vector2
	return Vector2.new(vector3.X, vector3.Z)
end

local function vector3FromVector2AndY(vector2: Vector2, y: number): Vector3
	return Vector3.new(vector2.X, y, vector2.Y)
end

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
	
local function getCurveVector2(
	originPosition: Vector2,
	originDirection: Vector2,
	goalPosition: Vector2,
	t: number
): Vector2
	local goalToOriginLength = Vector2.new(
		(goalPosition.X - originPosition.X),
		(goalPosition.Y - originPosition.Y)
	)
	local goalToOriginDotProduct = originDirection.Unit:Dot(goalToOriginLength.Unit)
	local goalToOriginDistance = (goalToOriginLength.Magnitude * goalToOriginDotProduct)

	local curveX = MathCurves.NthBezierCurve(
		t,	

		curveControlPointsFromCurveLerpValues(
			originPosition.X,
			originDirection.X,
			goalPosition.X,
			goalToOriginDistance,
			CURVE_LERP_VALUES
		)
	)
	local curveY = MathCurves.NthBezierCurve(
		t,	

		curveControlPointsFromCurveLerpValues(
			originPosition.Y,
			originDirection.Y,
			goalPosition.Y,
			goalToOriginDistance,
			CURVE_LERP_VALUES
		)
	)

	return Vector2.new(curveX, curveY)
end

--[[
	ROAD POINT Creation
]]

type RoadPointData = {
	position: Vector2,
	roadYLevel: number
}

local function roadPointData(position: Vector2, roadYLevel: number): RoadPointData
	return {
		position = position,
		roadYLevel = roadYLevel
	}
end

local function createRoadPoint(
	roadAsset: BasePart, 
	
	createType: string, 
	parent: Instance, 
	
	data: RoadPointData
): (BasePart, Vector2)
	local position = data.position
	local roadYLevel = data.roadYLevel

	local newRoadPoint = roadAsset:Clone()
	newRoadPoint.Parent = parent
	newRoadPoint.Anchored = true
	newRoadPoint.Position = Vector3.new(position.X, roadYLevel, position.Y)

	local createTypeProperties = CREATE_TYPE_TO_PART_PROPERTIES[createType]
	if createTypeProperties then
		applyArrayToProperties(newRoadPoint, createTypeProperties.roadPoint)
	end

	return newRoadPoint, vector2FromVector3(newRoadPoint.Position)
end

--[[
	ROAD Creation
]]

type RoadData = {
	originPosition: Vector2,
	goalPosition: Vector2,
	roadYLevel: number
}

local function roadData(originPosition: Vector2, goalPosition: Vector2, roadYLevel: number): RoadPointData
	return {
		originPosition = originPosition,
		goalPosition = goalPosition,
		roadYLevel = roadYLevel
	}
end

local function createRoad(
	roadAsset: BasePart, 

	createType: string, 
	parent: Instance, 
	
	data: RoadData
): BasePart
	local originPosition = data.originPosition
	local goalPosition = data.goalPosition

	local roadYLevel = data.roadYLevel
	local roadLength = (goalPosition - originPosition).Magnitude
	local roadCenterPosition = Vector2.new(
		math.lerp(originPosition.X, goalPosition.X, .5),
		math.lerp(originPosition.Y, goalPosition.Y, .5)
	)

	local newRoad = roadAsset:Clone()
	newRoad.Parent = parent
	newRoad.Anchored = true
	newRoad.Size = Vector3.new(roadLength, newRoad.Size.Y, newRoad.Size.Z)
	newRoad.CFrame = CFrame.lookAt(
		vector3FromVector2AndY(roadCenterPosition, roadYLevel), 
		vector3FromVector2AndY(goalPosition, roadYLevel)
	) * CFrame.Angles(0, ROAD_ANGLE_CORRECTION, 0)

	local createTypeProperties = CREATE_TYPE_TO_PART_PROPERTIES[createType]
	if createTypeProperties then
		applyArrayToProperties(newRoad, createTypeProperties.road)
	end

	return newRoad
end

local function createRoadExtension(
	roadPointAsset: BasePart,
	roadAsset: BasePart,

	createType: string,
	roadParent: Instance,

	data: RoadData
): (BasePart, BasePart)
	local originPosition = data.originPosition
	local goalPosition = data.goalPosition
	local roadYLevel = data.roadYLevel

	local newRoadPoint, newRoadPointPosition = createRoadPoint(
		roadPointAsset,
		createType,
		roadParent,
		roadPointData(
			goalPosition,
			roadYLevel
		)
	)
	local newRoad = createRoad(
		roadAsset, 
		createType,
		roadParent,
		roadData(
			originPosition, 
			newRoadPointPosition, 
			roadYLevel
		)
	)

	return newRoadPoint, newRoad 
end

-- creates SelectedRoadData
local function selectedRoadData(
	instance: BasePart, 
	pointVector2Data: RoadBuilderEnums.PointVector2Data
): RoadBuilderEnums.SelectedRoadData
	return {
		instance = instance,
		pointVector2Data = pointVector2Data
	}
end

--// PUBLIC

--[[	
	Creates a RoadConfig, used for the identity of the road.
]]
function Creation.RoadConfig(
	roadType: string, 
	createType: string,
	roadParent: Instance
)
	return {
		roadType = roadType,
		createType = createType,
		roadParent = roadParent
	}
end

--[[
	Creates a PointVector2Data, used for all road Creation methods. Automatically converts Vector3s into Vector2s to support module's preferred vector type.
	
	Use `yLevel` to dictate Vector3 Y level.
]]
function Creation.PointVector2Data(
	position: Vector3 | Vector2, 
	direction: (Vector3 | Vector2)?, 
	yLevel: number?
): RoadBuilderEnums.PointVector2Data
	local isPositionVector3 = (typeof(position) == "Vector3")
	local isdirectionVector3 = (typeof(direction) == "Vector3")

	return {
		position = isPositionVector3 and vector2FromVector3(position) or position;
		direction = direction 
			and (
				isdirectionVector3 
					and vector2FromVector3(direction) 
					or direction
			)
			or DEFAULT_ROAD_DIRECTION;
		yLevel = yLevel 
			or (
				isPositionVector3 
					and position.Y
					or error(`No Y level specified, yet "position" is not a Vector3`)
			)
	}
end

--[[
	Creates a road origin, needs only origin PointVector2Data.

	Vector3 Y Level defaults to `originVector2Data.yLevel`, but you can override with `overrideYLevel`
]]
function Creation.CreateOriginRoad(
	roadConfig: RoadBuilderEnums.RoadConfig,

	originVector2Data: RoadBuilderEnums.PointVector2Data,
	overrideYLevel: number?
): RoadBuilderEnums.SelectedRoadData
	local roadType = roadConfig.roadType
	local createType = roadConfig.createType
	local roadParent = roadConfig.roadParent
	local goalPosition = originVector2Data.position
	local goalYLevel = overrideYLevel or originVector2Data.yLevel

	local ROAD_POINT_ASSET = ASSETS.roadPoint[roadType]

	local newRoadPoint = createRoadPoint(
		ROAD_POINT_ASSET,
		createType,
		roadParent,
		roadPointData(
			goalPosition,
			goalYLevel
		)
	)

	return selectedRoadData(
		newRoadPoint,
		Creation.PointVector2Data(
			newRoadPoint.Position
		)
	)
end

--[[
	Validates an extension road (in other words, the curve) to see if the delta angle from origin to first bezier point approaching goal exceeds a maximum angle.

	Maximum angle defaults to `CURVE_ANGLE_MAXIMUM`, but you can override with `overrideMaximumAngle`.
]]
function Creation.ValidateExtensionRoad(
	originVector2Data: RoadBuilderEnums.PointVector2Data,
	goalVector2Data: RoadBuilderEnums.PointVector2Data,
	overrideMaximumAngle: number?
): boolean
	local originPosition = originVector2Data.position
	local originDirection = originVector2Data.direction
	local goalPosition = goalVector2Data.position
	local originToGoalDistance = (originPosition - goalPosition).Magnitude
	local curveFrequency = CURVE_FREQUENCY_PER_N_STUDS.frequency * (originToGoalDistance / CURVE_FREQUENCY_PER_N_STUDS.nStuds)
	local maximumCurveAngle = overrideMaximumAngle or CURVE_ANGLE_MAXIMUM

	-- first bezier point approaching goal
	local curvePosition = getCurveVector2(
		originPosition,
		originDirection,
		goalPosition,
		(1/curveFrequency)
	)
	local curveDirection = (curvePosition - originPosition).Unit

	local originToCurveDotAngle = MathGeneral.DotAngleBetween(originDirection, curveDirection)

	return (originToCurveDotAngle <= maximumCurveAngle)
end

--[[
	Creates a road point at the goal, and a curved road from origin approaching goal (created road point).
]]
function Creation.CreateExtensionRoad(
	roadConfig: RoadBuilderEnums.RoadConfig,

	originVector2Data: RoadBuilderEnums.PointVector2Data, 
	goalVector2Data: RoadBuilderEnums.PointVector2Data,
	overrideYLevel: number?
): RoadBuilderEnums.SelectedRoadData
	local roadType = roadConfig.roadType
	local createType = roadConfig.createType
	local roadParent = roadConfig.roadParent
	local originPosition = originVector2Data.position
	local originDirection = originVector2Data.direction
	local goalPosition = goalVector2Data.position
	local roadYLevel = overrideYLevel or originVector2Data.yLevel
	local originToGoalDistance = (originPosition - goalPosition).Magnitude
	local curveFrequency = CURVE_FREQUENCY_PER_N_STUDS.frequency * (originToGoalDistance / CURVE_FREQUENCY_PER_N_STUDS.nStuds)

	local ROAD_ASSET = ASSETS.road[roadType]
	local ROAD_POINT_ASSET = ASSETS.roadPoint[roadType]

	-- state
	local previousRoadPointPosition: Vector2 = originPosition

	--[[
		bezier curve: make road follow alongside this curve approaching "goalPosition"

		(1/curveFrequency) implies how many road points will be made 
		between the origin and destination
	]]
	for t = 0, 1, 1/curveFrequency do
		local curvePosition = getCurveVector2(
			originPosition, 
			originDirection,
			goalPosition, 
			t
		)

		local newRoadPoint, _ = createRoadExtension(
			ROAD_POINT_ASSET,
			ROAD_ASSET,

			createType,
			roadParent,

			roadData(
				previousRoadPointPosition,
				curvePosition,
				roadYLevel
			)
		)

		previousRoadPointPosition = vector2FromVector3(newRoadPoint.Position)
	end

	-- make final road directly on "goalPosition"
	local endRoadPoint = createRoadExtension(
		ROAD_POINT_ASSET,
		ROAD_ASSET,

		createType,
		roadParent,

		roadData(
			previousRoadPointPosition,
			goalPosition,
			roadYLevel
		)
	)

	-- direction vector3 from last point to goal point (used for angle validation)
	local goalDirection = (
		vector3FromVector2AndY(goalPosition, roadYLevel) 
		- vector3FromVector2AndY(previousRoadPointPosition, roadYLevel)
	).Unit

	return selectedRoadData(
		endRoadPoint, 
		Creation.PointVector2Data(
			goalPosition,
			goalDirection,
			roadYLevel
		)
	)
end

return Creation
	