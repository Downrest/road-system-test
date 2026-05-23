local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local RoadBuilderCache = require(ReplicatedStorage.RoadBuilder.RoadBuilderCache)
local RoadCache = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.CacheDataWrappers.RoadCache)
local RoadPointCache = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.CacheDataWrappers.RoadPointCache)
local PointVector2Data = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.PointVector2Data)
local RoadConfigData = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.RoadConfigData)
local RoadCreationOutputData = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.RoadCreationOutputData)
local CreateTypeEnums = require(ReplicatedStorage.RoadBuilder.RoadBuilderEnums.CreateTypeEnums)
local RoadInstanceTagEnums = require(ReplicatedStorage.RoadBuilder.RoadBuilderEnums.RoadInstanceTagEnums)
local RoadTypeEnums = require(ReplicatedStorage.RoadBuilder.RoadBuilderEnums.RoadTypeEnums)
local RoadBuilderPresets = require(ReplicatedStorage.RoadBuilder.RoadBuilderPresets)
local RoadBuilderAssetGetter = require(ReplicatedStorage.RoadBuilder.RoadBuilderAssetGetter)
local create = require(ReplicatedStorage.SharedPackages.Vide.create)
local MathCurves = require(ReplicatedStorage.SharedUtils.MathUtils.MathCurves)
local MathEasing = require(ReplicatedStorage.SharedUtils.MathUtils.MathEasing)
local MathGeneral = require(ReplicatedStorage.SharedUtils.MathUtils.MathGeneral)
local PropertiesUtils = require(ReplicatedStorage.SharedUtils.PropertiesUtils)
local VectorUtils = require(ReplicatedStorage.SharedUtils.VectorUtils)

local Creation = {}

--// CONFIGURATION

-- publicly exposed constant because its needed by RoadBuilderClient for its own road simulation
Creation.DEFAULT_ROAD_POINT_AXIS = Vector2.xAxis

local ASSETS = {
	road = {
		[RoadTypeEnums.Gravel] = RoadBuilderAssetGetter.roadAssets[RoadTypeEnums.Gravel].road;
		[RoadTypeEnums.Mud] = RoadBuilderAssetGetter.roadAssets[RoadTypeEnums.Mud].road;
	};
	roadPoint = {
		[RoadTypeEnums.Gravel] = RoadBuilderAssetGetter.roadAssets[RoadTypeEnums.Gravel].roadPoint;
		[RoadTypeEnums.Mud] = RoadBuilderAssetGetter.roadAssets[RoadTypeEnums.Mud].roadPoint;
	};
}

-- limits road points from getting closer in distance between either origin or goal beyond this value
local CURVE_EDGE_LIMIT = 2.5

-- amount of road points per nStuds is created in the entire road extension curve
local CURVE_FREQUENCY_PER_N_STUDS = {
	frequency = 1,
	nStuds = 5
}

--[[
	control points for bezier curve ranging [0, 1], depicts the expected road curve
]]
local CURVE_LERP_VALUES = {
	MathEasing.GetEasingPointsTuple(10, MathEasing.EaseInSine)
}

local CURVE_ANGLE_MAXIMUM = 45

local ROAD_ANGLE_CORRECTION = math.pi/2

local ROAD_TYPE_TO_VISUALIZE_PROPERTIES = {
	[RoadTypeEnums.Gravel] = RoadBuilderPresets.RoadTypeData[RoadTypeEnums.Gravel].VisualizeProperties;
	[RoadTypeEnums.Mud] = RoadBuilderPresets.RoadTypeData[RoadTypeEnums.Mud].VisualizeProperties;
}

local Z_FIGHTING_Y_OFFSET = .001

--// INTERNAL

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

local function applyVisualizeProperties(
	createType: CreateTypeEnums.CreateTypeEnums,
	roadType: RoadTypeEnums.RoadTypeEnums,
	roadPart: BasePart
)
	if createType ~= CreateTypeEnums.Visualize then
		return
	end

	local createTypeProperties = ROAD_TYPE_TO_VISUALIZE_PROPERTIES[roadType]
	if not createTypeProperties then
		return
	end

	PropertiesUtils.ApplyProperties(roadPart, createTypeProperties.roadPoint)
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

local function createRoadPoint(
	roadAsset: BasePart, 
	
	roadType: RoadTypeEnums.RoadTypeEnums,
	createType: CreateTypeEnums.CreateTypeEnums, 
	parent: Instance, 
	
	pointData: PointVector2Data.PointVector2Data
): (BasePart, Vector2)
	local pointPosition = pointData.position
	local pointYLevel = pointData.yLevel

	local newRoadPoint = roadAsset:Clone()
	newRoadPoint.Parent = parent
	newRoadPoint.Anchored = true
	newRoadPoint.Position = VectorUtils.Vector3FromVector2AndY(pointPosition, pointYLevel)
	newRoadPoint:AddTag(RoadInstanceTagEnums.RoadPoint)

	applyVisualizeProperties(createType, roadType, newRoadPoint)

	-- caching
	RoadBuilderCache.AddRoadPoint(
		newRoadPoint, 
		RoadPointCache(
			{}, -- usually placeholder, unless a standalone road point is created
			nil
		)
	)

	return newRoadPoint, VectorUtils.Vector2FromVector3(newRoadPoint.Position)
end

local function createRoad(
	roadAsset: BasePart, 

	roadType: RoadTypeEnums.RoadTypeEnums,
	createType: CreateTypeEnums.CreateTypeEnums, 
	parent: Instance, 
	
	originData: PointVector2Data.PointVector2Data,
	goalData: PointVector2Data.PointVector2Data
): BasePart
	local originPosition = originData.position
	local goalPosition = goalData.position

	--TODO PLACEHOLDER FOR Y LEVEL, in the future will support differing yLevels between origin and goal
	local roadYLevel = originData.roadYLevel

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
		VectorUtils.Vector3FromVector2AndY(roadCenterPosition, roadYLevel), 
		VectorUtils.Vector3FromVector2AndY(goalPosition, roadYLevel)
	) * CFrame.Angles(0, ROAD_ANGLE_CORRECTION, 0)

	applyVisualizeProperties(createType, roadType, newRoad)

	return newRoad
end

-- merges both createRoad() and createRoadPoint()
local function createRoadExtension(
	roadPointAsset: BasePart,
	roadAsset: BasePart,

	roadType: RoadTypeEnums.RoadTypeEnums,
	createType: CreateTypeEnums.CreateTypeEnums,
	roadParent: Instance,

	originData: PointVector2Data.PointVector2Data,
	goalData: PointVector2Data.PointVector2Data
): (BasePart, BasePart, Vector2?)
	-- default creation
	if createType == CreateTypeEnums.Default then
		local originRoadPoint = RoadBuilderCache.GetRoadInstanceFromVector3(
			VectorUtils.Vector3FromVector2AndY(originData.position, originData.yLevel)
		)
		local originRoadPointCache = RoadBuilderCache.GetRoadPointCache(originRoadPoint)
		local goalRoadPoint = RoadBuilderCache.GetRoadInstanceFromVector3(
			VectorUtils.Vector3FromVector2AndY(goalData.position, goalData.yLevel)
		)
		local goalRoadPointCache = RoadBuilderCache.GetRoadPointCache(goalRoadPoint)

		local newRoad = createRoad(
			roadAsset, 
			roadType,
			createType,
			roadParent,
			originData,
			goalData
		)

		local returnedRoadPoint: BasePart
		local returnedRoad: BasePart
		local returnedVector2Direction: Vector2

		-- if already cached, do not override roadpoint cache
		if goalRoadPoint then
			local goalRoadPointCache = RoadBuilderCache.GetRoadPointCache(goalRoadPoint)

			returnedRoadPoint = goalRoadPoint
			returnedRoad = newRoad
			returnedVector2Direction = goalRoadPointCache.vector2Direction

		-- if not yet, update roadpoint cache with new direction
		else
			local newRoadPoint = createRoadPoint(
				roadPointAsset,
				roadType,
				createType,
				roadParent,
				goalData
			)
			
			local newRoadToGoalDirection = (
				VectorUtils.Vector2FromVector3(newRoadPoint.Position) 
				- VectorUtils.Vector2FromVector3(newRoad.Position)
			).Unit
			RoadBuilderCache.RoadPointCacheList[newRoadPoint].vector2Direction = newRoadToGoalDirection

			returnedRoadPoint = newRoadPoint
			returnedRoad = newRoad
			returnedVector2Direction = newRoadToGoalDirection
		end

		--TODO INSERT `returnedRoad` to dependentRoadInstances of ORIGIN ROAD POINT AND GOAL ROAD POINT

		if originRoadPointCache then
			table.insert(RoadBuilderCache.RoadPointCacheList[originRoadPoint].dependentRoads, returnedRoad)
		end
		if goalRoadPointCache then
			table.insert(RoadBuilderCache.RoadPointCacheList[goalRoadPoint].dependentRoads, returnedRoad)
		end
		
		return returnedRoadPoint, returnedRoad, returnedVector2Direction

	-- visualize (no care about caching here, just make road extensions)
	else
		local newRoadPoint = createRoadPoint(
			roadPointAsset,
			roadType,
			createType,
			roadParent,
			goalData
		)
		local newRoad = createRoad(
			roadAsset, 
			roadType,
			createType,
			roadParent,
			originData,
			goalData
		)

		return newRoadPoint, newRoad 
	end
end

local function assertCreateDefaultTypeToServer(createType: CreateTypeEnums.CreateTypeEnums)
	if createType == CreateTypeEnums.Default then
		assert(RunService:IsServer(), "Passing `CreateTypeEnums.Default` can only be done on the server")
	end
end

--[[
	applies `Creation.DEFAULT_ROAD_POINT_AXIS` if `data.direction` is nil
]]
local function applyDefaultDirectionToVector2Data(data: PointVector2Data.PointVector2Data): PointVector2Data.PointVector2DataEnsuredDir
	if not data.direction then
		data.direction = Creation.DEFAULT_ROAD_POINT_AXIS
	end
	return data
end

--// PUBLIC

--[[
	Creates a road origin, needs only origin PointVector2Data.

	Vector3 Y Level defaults to `originVector2Data.yLevel`, but you can override with `overrideYLevel`
]]
function Creation.CreateOriginRoad(
	roadConfig: RoadConfigData.RoadConfigData,

	originVector2Data: PointVector2Data.PointVector2Data
): RoadCreationOutputData.RoadCreationOutputData
	originVector2Data = applyDefaultDirectionToVector2Data(originVector2Data)

	local roadType = roadConfig.roadType
	local createType = roadConfig.createType
	assertCreateDefaultTypeToServer(createType)
	local roadParent = roadConfig.roadParent

	local ROAD_POINT_ASSET = ASSETS.roadPoint[roadType]

	local newRoadPoint = createRoadPoint(
		ROAD_POINT_ASSET,
		roadType,
		createType,
		roadParent,
		originVector2Data
	)

	return RoadCreationOutputData(
		newRoadPoint,
		PointVector2Data(
			newRoadPoint.Position
		)
	)
end

--[[
	Validates an extension road (in other words, the curve) to see if the delta angle from origin to first bezier point approaching goal exceeds a maximum angle.

	Maximum angle defaults to `CURVE_ANGLE_MAXIMUM`, but you can override with `overrideMaximumAngle`.
]]
function Creation.ValidateExtensionRoad(
	originVector2Data: PointVector2Data.PointVector2Data,
	goalVector2Data: PointVector2Data.PointVector2Data,
	overrideMaximumAngle: number?
): boolean
	originVector2Data = applyDefaultDirectionToVector2Data(originVector2Data)

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
	roadConfig: RoadConfigData.RoadConfigData,

	originVector2Data: PointVector2Data.PointVector2Data, 
	goalVector2Data: PointVector2Data.PointVector2Data
): RoadCreationOutputData.RoadCreationOutputData
	originVector2Data = applyDefaultDirectionToVector2Data(originVector2Data)

	local roadType = roadConfig.roadType
	local createType = roadConfig.createType
	assertCreateDefaultTypeToServer(createType)
	local roadParent = roadConfig.roadParent

	local originPosition = originVector2Data.position
	local originDirection = originVector2Data.direction
	local originYLevel = originVector2Data.yLevel
	
	local goalPosition = goalVector2Data.position
	local goalYLevel = goalVector2Data.yLevel
	
	local originToGoalDistance = (originPosition - goalPosition).Magnitude
	local curveFrequency = CURVE_FREQUENCY_PER_N_STUDS.frequency * (originToGoalDistance / CURVE_FREQUENCY_PER_N_STUDS.nStuds)

	local ROAD_ASSET = ASSETS.road[roadType]
	local ROAD_POINT_ASSET = ASSETS.roadPoint[roadType]

	local dependentRoads = {
		roadPoints = {};
		roads = {};
		n = 0;
	}
	local previousRoadPointPosition: Vector2 = originPosition

	--[[
		bezier curve: make road follow alongside this curve approaching "goalPosition"

		(1/curveFrequency) implies how many road points will be made 
		between the origin and destination
	]]
	for t = 0, 1, 1/curveFrequency do
		t = MathEasing.EaseOutSine(t)
		--[[
			--TODO 
			
			this could be a function that stores already the originPos originDir
			but youd just method chain to get a new vector2, like say
			newCurveVector2(...).get(t)
		]]
		local curvePosition = getCurveVector2(
			originPosition, 
			originDirection,
			goalPosition, 
			t
		)
		local curveToOriginMagnitude = (curvePosition - originPosition).Magnitude
		local curveToGoalMagnitude = (curvePosition - goalPosition).Magnitude
		
		if curveToOriginMagnitude <= CURVE_EDGE_LIMIT or curveToGoalMagnitude <= CURVE_EDGE_LIMIT then
			continue
		end

		local newRoadPoint, newRoad = createRoadExtension(
			ROAD_POINT_ASSET,
			ROAD_ASSET,

			roadType,
			createType,
			roadParent,

			PointVector2Data(previousRoadPointPosition, nil, originYLevel),
			PointVector2Data(curvePosition, nil, goalYLevel)
		)
		table.insert(dependentRoads.roadPoints, newRoadPoint)
		table.insert(dependentRoads.roads, newRoad)
		dependentRoads.n += 2

		previousRoadPointPosition = curvePosition
	end

	-- make final road directly on "goalPosition"
	local goalRoadPoint, goalRoad, goalDirection = createRoadExtension(
		ROAD_POINT_ASSET,
		ROAD_ASSET,

		roadType,
		createType,
		roadParent,

		PointVector2Data(previousRoadPointPosition, nil, originYLevel),
		PointVector2Data(goalPosition, nil, goalYLevel)
	)
	table.insert(dependentRoads.roads, goalRoad)
	dependentRoads.n += 1
	
	return RoadCreationOutputData(
		goalRoadPoint, 
		PointVector2Data(
			goalPosition,
			goalDirection,
			goalYLevel
		),

		dependentRoads
	)
end

return Creation
	