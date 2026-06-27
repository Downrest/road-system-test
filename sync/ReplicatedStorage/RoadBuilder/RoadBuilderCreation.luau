local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local RoadBuilderCache = require(ReplicatedStorage.RoadBuilder.RoadBuilderCache)
--TODO: why is this unused?
local RoadCache = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.CacheDataWrappers.RoadCache)
local RoadPointCache = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.CacheDataWrappers.RoadPointCache)
local PointVector2Data = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.PointVector2Data)
local RoadConfigData = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.RoadConfigData)
local RoadCreationOutputData = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.RoadCreationOutputData)
local CreateTypeEnums = require(ReplicatedStorage.RoadBuilder.RoadBuilderEnums.CreateTypeEnums)
local RoadInstanceTagEnums = require(ReplicatedStorage.RoadBuilder.RoadBuilderEnums.RoadInstanceTagEnums)
local RoadTypeEnums = require(ReplicatedStorage.RoadBuilder.RoadBuilderEnums.RoadTypeEnums)
local RoadBuilderAssetGetter = require(ReplicatedStorage.RoadBuilder.RoadBuilderAssetGetter)
local RoadCreationConfig = require(ReplicatedStorage.RoadBuilder.RoadBuilderConfig.RoadCreationConfig)
local DefaultCreateType = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.CreatePropertyWrappers.DefaultCreateType)
local ExtensionConfigData = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.ExtensionConfigData)
local RoadPointCacheTypeEnums = require(ReplicatedStorage.RoadBuilder.RoadBuilderEnums.RoadPointCacheTypeEnums)
local RoadVariantEnums = require(ReplicatedStorage.RoadBuilder.RoadBuilderEnums.RoadVariantEnums)
local RoadBuilderCurveUtils = require(ReplicatedStorage.RoadBuilder.RoadBuilderUtils.RoadBuilderCurveUtils)
local PropertiesUtils = require(ReplicatedStorage.SharedUtils.PropertiesUtils)
local TableUtils = require(ReplicatedStorage.SharedUtils.TableUtils)
local VectorUtils = require(ReplicatedStorage.SharedUtils.VectorUtils)

local Creation = {}

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
local ROAD_ANGLE_CORRECTION = math.pi/2
--TODO: do something son
local Z_FIGHTING_Y_OFFSET = .001

local function applyCreateTypeProperties(
	roadConfig: RoadConfigData.RoadConfigData,
	isRoadPoint: boolean,
	roadPart: BasePart
)

	PropertiesUtils.ApplyProperties(
		roadPart, 
		isRoadPoint
			and roadConfig.createType.visualizedProperties.roadPoint
			or roadConfig.createType.visualizedProperties.road
	)

	--warn(`MODIFIED {roadPart} of TAG {roadConfig.createType.tag}`, roadPart.CanQuery)
end

local function assertCreateDefaultTypeToServer(defaultCreateType: DefaultCreateType.DefaultCreateType): boolean
	local isCreateTypeDefault = (defaultCreateType.tag == CreateTypeEnums.Default)
	if isCreateTypeDefault then
		assert(RunService:IsServer(), "Passing `CreateTypeEnums.Default` can only be done on the server")
	end

	return isCreateTypeDefault
end

local function ifCreateTypeDefault(
	roadConfig: RoadConfigData.RoadConfigData, 
	callback: () -> ()
)
	if roadConfig.createType.tag == CreateTypeEnums.Default then
		callback()
	end
end

local function createRoadPoint(
	roadAsset: BasePart, 
	
	roadConfig: RoadConfigData.RoadConfigData,
	roadVariant: RoadVariantEnums.RoadVariantEnums,
	parent: Instance, 
	
	toPointData: PointVector2Data.PointVector2Data,
	directionToData: PointVector2Data.PointVector2Data?,
	shouldBeCachedAsEndPoint: boolean?
): (BasePart, Vector2)
	local pointPosition = toPointData.position
	local pointYLevel = toPointData.yLevel

	local newRoadPoint = roadAsset:Clone()
	newRoadPoint.Parent = parent
	newRoadPoint.Anchored = true

	if directionToData then
		newRoadPoint.CFrame = CFrame.lookAt(
			VectorUtils.Vector3FromVector2AndY(pointPosition, pointYLevel),
			VectorUtils.Vector3FromVector2AndY(directionToData.position, directionToData.yLevel)
		)
	else
		newRoadPoint.Position = VectorUtils.Vector3FromVector2AndY(pointPosition, pointYLevel)
	end

	applyCreateTypeProperties(roadConfig, true, newRoadPoint)

	ifCreateTypeDefault(roadConfig, function()
		newRoadPoint:AddTag(RoadInstanceTagEnums.RoadPoint)
		newRoadPoint:AddTag(
			shouldBeCachedAsEndPoint
				and RoadPointCacheTypeEnums.EndPoint
				or RoadPointCacheTypeEnums.DependentPoint
		)

		RoadBuilderCache.SetRoadPointCache(
			newRoadPoint, 
			RoadPointCache(
				shouldBeCachedAsEndPoint and RoadPointCacheTypeEnums.EndPoint or RoadPointCacheTypeEnums.DependentPoint,
				{}, -- will contain other end roadpoints connected to this roadpoint
				{}, -- usually placeholder, unless a standalone road point is created
				RoadCreationConfig.DEFAULT_ROAD_POINT_AXIS
			),
			true
		)
	end)

	return newRoadPoint, VectorUtils.Vector2FromVector3(newRoadPoint.Position)
end

local function createRoad(
	roadAsset: BasePart, 

	roadConfig: RoadConfigData.RoadConfigData,
	roadVariant: RoadVariantEnums.RoadVariantEnums,
	parent: Instance, 
	
	fromRoadData: PointVector2Data.PointVector2Data,
	toRoadData: PointVector2Data.PointVector2Data
): BasePart
	local originPosition = fromRoadData.position
	local goalPosition = toRoadData.position

	local roadYLevel = (fromRoadData.yLevel + toRoadData.yLevel)/2

	local roadLength = (
		VectorUtils.Vector3FromVector2AndY(originPosition, fromRoadData.yLevel) 
		- VectorUtils.Vector3FromVector2AndY(goalPosition, toRoadData.yLevel) 
	).Magnitude
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
		VectorUtils.Vector3FromVector2AndY(goalPosition, toRoadData.yLevel)
	) * CFrame.Angles(0, ROAD_ANGLE_CORRECTION, 0)

	applyCreateTypeProperties(roadConfig, false, newRoad)

	ifCreateTypeDefault(roadConfig, function()
		RoadBuilderCache.SetRoadCache(
			newRoad, 
			RoadCache(
				{}
			),
			true
		)
	end)

	return newRoad
end

-- merges both createRoad() and createRoadPoint()
local function createRoadExtension(
	roadPointAsset: BasePart,
	roadAsset: BasePart,

	roadConfig: RoadConfigData.RoadConfigData,
	roadVariant: RoadVariantEnums.RoadVariantEnums,

	fromExtenstionData: PointVector2Data.PointVector2Data,
	toExtensionData: PointVector2Data.PointVector2Data,
	extensionConfigData: ExtensionConfigData.ExtensionConfigData?
): (BasePart, BasePart, Vector2?)

	-- default creation
	if roadConfig.createType.tag == CreateTypeEnums.Default then
		local isEndPoint = extensionConfigData and extensionConfigData.isEndPoint

		--[[
			CHECKING CACHE
		]]

		-- can be nil, depending on whether or not its extending to a pre-existing roadpoint
		local goalRoadPoint = RoadBuilderCache.GetRoadInstanceFromVector3(
			VectorUtils.Vector3FromVector2AndY(
				toExtensionData.position, 
				toExtensionData.yLevel
			)
		)
		local goalRoadPointCache = RoadBuilderCache.GetRoadPointCache(goalRoadPoint)

		--[[
			ROAD EXTENSION CREATION
		]]

		local originToGoalRoad = createRoad(
			roadAsset, 
			roadConfig,
			roadVariant,
			RoadCreationConfig.ROAD_PARENTS.road,
			fromExtenstionData,
			toExtensionData
		)

		local goalVector2Direction: Vector2

		-- if already cached, do not override roadpoint cache
		if goalRoadPointCache then
			goalVector2Direction = goalRoadPointCache.vector2Direction

		-- if not yet, override goalroadpoint + update goalroadpoint cache with new direction
		else
			goalRoadPoint = createRoadPoint(
				roadPointAsset,
				roadConfig,
				roadVariant,
				RoadCreationConfig.ROAD_PARENTS.roadPoint,
				toExtensionData,
				fromExtenstionData,
				isEndPoint
			)
			
			local newRoadToGoalDirection = (
				VectorUtils.Vector2FromVector3(goalRoadPoint.Position) 
				- VectorUtils.Vector2FromVector3(originToGoalRoad.Position)
			).Unit

			goalVector2Direction = newRoadToGoalDirection

			goalRoadPointCache = RoadBuilderCache.RoadPointCacheList[goalRoadPoint]
			goalRoadPointCache.vector2Direction = newRoadToGoalDirection
		end

		if isEndPoint then
			local endPointCaches = {
				originRoadPointCache = RoadBuilderCache.GetRoadPointCache(extensionConfigData.originRoadPoint);
				goalRoadPointCache = goalRoadPointCache;
			}

			for _, endPointCache: RoadPointCache.RoadPointCache in endPointCaches do
				for _, dependent: BasePart in TableUtils.MergeArray(extensionConfigData.endPointDependents, originToGoalRoad) do
					-- we expect `dependentRoads` to already exist as a table
					table.insert(endPointCache.dependentRoads, dependent)

					local dependentRoadCache = RoadBuilderCache.GetRoadCache(dependent)
					if dependentRoadCache then
						table.insert(dependentRoadCache.dependeeRoadPoints, extensionConfigData.originRoadPoint)
					end
				end

				table.insert(
					endPointCache.pairExtensionEndRoadPoints, 
					(endPointCache == endPointCaches.originRoadPointCache)
						and goalRoadPoint
						or extensionConfigData.originRoadPoint
				)
			end

			RoadBuilderCache.QueueReplicationCache(
				extensionConfigData.originRoadPoint.Position,
				endPointCaches.originRoadPointCache,
				RoadBuilderCache.TARGET_CACHE_TYPE_ENUMS.TargetRoadPoint
			)
			RoadBuilderCache.QueueReplicationCache(
				goalRoadPoint.Position,
				endPointCaches.goalRoadPointCache,
				RoadBuilderCache.TARGET_CACHE_TYPE_ENUMS.TargetRoadPoint
			)
			RoadBuilderCache.SendBatchedReplicationCache()

			-- local originRoadPointCache = RoadBuilderCache.GetRoadPointCache(extensionConfigData.originRoadPoint)
			-- if originRoadPointCache then
			-- 	for _, dependent in extensionConfigData.endPointDependents do
			-- 		-- we expect `dependentRoads` to already exist as a table
			-- 		table.insert(originRoadPointCache.dependentRoads, dependent)

			-- 		local dependentRoadCache = RoadBuilderCache.GetRoadCache(dependent)
			-- 		if dependentRoadCache then
			-- 			table.insert(dependentRoadCache.dependeeRoadPoints, extensionConfigData.originRoadPoint)
			-- 		end
			-- 	end
			-- 	table.insert(originRoadPointCache.dependentRoads, originToGoalRoad)

			-- 	table.insert(originRoadPointCache.pairExtensionEndRoadPoints, goalRoadPoint)
			-- end

			-- if goalRoadPointCache then
			-- 	for _, dependent in extensionConfigData.endPointDependents do
			-- 		-- we expect `dependentRoads` to already exist as a table
			-- 		table.insert(goalRoadPointCache.dependentRoads, dependent)

			-- 		local dependentRoadCache = RoadBuilderCache.GetRoadCache(dependent)
			-- 		if dependentRoadCache then
			-- 			table.insert(dependentRoadCache.dependeeRoadPoints, extensionConfigData.originRoadPoint)
			-- 		end
			-- 	end
			-- 	table.insert(goalRoadPointCache.dependentRoads, originToGoalRoad)

			-- 	table.insert(goalRoadPointCache.pairExtensionEndRoadPoints, extensionConfigData.originRoadPoint)
			-- end
		end
		
		return goalRoadPoint, originToGoalRoad, goalVector2Direction

	-- visualize (no care about caching here, just make road extensions)
	else
		local newRoadPoint = createRoadPoint(
			roadPointAsset,
			roadConfig,
			roadVariant,
			roadConfig.createType.parent,
			toExtensionData,
			fromExtenstionData
		)
		local newRoad = createRoad(
			roadAsset, 
			roadConfig,
			roadVariant,
			roadConfig.createType.parent,
			fromExtenstionData,
			toExtensionData
		)

		return newRoadPoint, newRoad 
	end
end

--// PUBLIC

--[[
	Creates a road origin, needs only origin PointVector2Data. Direction is not forced if left as empty.

	Vector3 Y Level defaults to `originVector2Data.yLevel`, but you can override with `overrideYLevel`
]]
--TODO: rename this to CreateOriginRoadPoint
function Creation.CreateOriginRoad(
	roadConfig: RoadConfigData.RoadConfigData,

	originVector2Data: PointVector2Data.PointVector2Data,
	shouldBeCachedAsEndPoint: boolean?
): RoadCreationOutputData.RoadCreationOutputData
	local roadType = roadConfig.roadType
	local createType = roadConfig.createType
	local isCreateTypeDefault = assertCreateDefaultTypeToServer(createType)

	local ROAD_POINT_ASSET = ASSETS.roadPoint[roadType]

	local newRoadPoint = createRoadPoint(
		ROAD_POINT_ASSET,
		roadConfig,
		RoadVariantEnums.RoadPoint,
		isCreateTypeDefault
			and RoadCreationConfig.ROAD_PARENTS.roadPoint
			or roadConfig.createType.parent,
		originVector2Data,
		nil, 
		shouldBeCachedAsEndPoint
	)

	-- if isCreateTypeDefault then
	-- 	RoadBuilderCache.SendBatchedReplicationCache()
	-- end
	
	return RoadCreationOutputData(
		newRoadPoint,
		PointVector2Data(
			newRoadPoint.Position
		)
	)
end

--[[
	Creates a road point at the goal, and a curved road from origin approaching goal (created road point).
]]
function Creation.CreateExtensionRoad(
	roadConfig: RoadConfigData.RoadConfigData,

	originVector2Data: PointVector2Data.PointVector2Data, 
	goalVector2Data: PointVector2Data.PointVector2Data
): RoadCreationOutputData.RoadCreationOutputData
	local originVector2DataWithDir = RoadCreationConfig.ApplyDefaultDirectionToVector2Data(originVector2Data)

	local roadType = roadConfig.roadType
	local createType = roadConfig.createType
	assertCreateDefaultTypeToServer(createType)

	local originPosition = originVector2DataWithDir.position
	local originDirection = originVector2DataWithDir.direction
	local originYLevel = originVector2DataWithDir.yLevel

	--TODO: LOWKEY IM PRETTY SURE MOST OF THEM MANUALLY INDEX and not use the functions
	-- WHEN ITS NOT SUPER NECESSARY, just double check
	local originRoadPoint: BasePart? = RoadBuilderCache.GetRoadInstanceFromVector3(
		VectorUtils.Vector3FromVector2AndY(originPosition, originYLevel)
	)
	
	local goalPosition = goalVector2Data.position
	local goalYLevel = goalVector2Data.yLevel
	
	local originToGoalDistance = (originPosition - goalPosition).Magnitude
	local curveFrequency = RoadCreationConfig.ROAD_CURVE_FREQUENCY_PER_N_STUDS.frequency 
		* (originToGoalDistance / RoadCreationConfig.ROAD_CURVE_FREQUENCY_PER_N_STUDS.nStuds)

	local ROAD_ASSET = ASSETS.road[roadType]
	local ROAD_POINT_ASSET = ASSETS.roadPoint[roadType]

	local dependentRoads = {
		roadPoints = {};
		roads = {};
		n = 0;
	}
	local previousRoadPointPosition: Vector2 = originPosition
	local previousRoadPointYLevel: number = originYLevel
	local previousRoadPointT = 0
	local curveInit = RoadBuilderCurveUtils.GetCurveVector2(
		originPosition, 
		originDirection,
		goalPosition
	)

	--[[
		bezier curve: make road follow alongside this curve approaching "goalPosition"

		(1/curveFrequency) implies how many road points will be made 
		between the origin and destination
	]]
	for t = 0, 1, 1/curveFrequency do
		local curveT = RoadCreationConfig.ROAD_CURVE_T_EASING.horizontal(t)
		local verticalT = RoadCreationConfig.ROAD_CURVE_T_EASING.vertical(t)

		local curvePosition = curveInit.get(curveT)
		local curveToOriginMagnitude = (curvePosition - originPosition).Magnitude
		local curveToGoalMagnitude = (curvePosition - goalPosition).Magnitude
		
		if 
			curveToOriginMagnitude <= RoadCreationConfig.ROAD_CURVE_EDGE_LIMIT 
			or curveToGoalMagnitude <= RoadCreationConfig.ROAD_CURVE_EDGE_LIMIT 
		then
			continue
		end

		local newRoadPoint, newRoad = createRoadExtension(
			ROAD_POINT_ASSET,
			ROAD_ASSET,

			roadConfig,
			RoadVariantEnums.RoadExtension,

			PointVector2Data(
				previousRoadPointPosition, 
				nil, 
				math.lerp(originYLevel, goalYLevel, previousRoadPointT)
			),
			PointVector2Data(
				curvePosition, 
				nil, 
				math.lerp(originYLevel, goalYLevel, verticalT)
			)
		)
		table.insert(dependentRoads.roadPoints, newRoadPoint)
		table.insert(dependentRoads.roads, newRoad)
		dependentRoads.n += 2

		previousRoadPointPosition = curvePosition
		previousRoadPointT = verticalT
		previousRoadPointYLevel = math.lerp(originYLevel, goalYLevel, verticalT)
	end

	-- make final road directly on "goalPosition"
	local goalRoadPoint, goalRoad, goalDirection = createRoadExtension(
		ROAD_POINT_ASSET,
		ROAD_ASSET,

		roadConfig,
		RoadVariantEnums.RoadExtension,

		PointVector2Data(previousRoadPointPosition, nil, previousRoadPointYLevel),
		PointVector2Data(goalPosition, nil, goalYLevel),
		ExtensionConfigData(
			true, 
			originRoadPoint,
			TableUtils.MergeArray(
				dependentRoads.roads,
				dependentRoads.roadPoints
			)
		)
	)
	-- goalRoadPoint.Color = Color3.new(1, 0, 0)
	table.insert(dependentRoads.roads, goalRoad)
	dependentRoads.n += 1

	-- ifCreateTypeDefault(roadConfig, function()
	-- 	-- batch send replication (to client)
	-- 	RoadBuilderCache.SendBatchedReplicationCache()
	-- end)
	
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
	