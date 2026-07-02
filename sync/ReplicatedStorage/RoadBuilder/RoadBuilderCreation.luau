local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local RoadBuilderCache = require(ReplicatedStorage.RoadBuilder.RoadBuilderCache)
local RoadCache = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.CacheDataWrappers.RoadCache)
local RoadPointCache = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.CacheDataWrappers.RoadPointCache)
local PointVector2Data = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.PointVector2Data)
local RoadConfigData = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.RoadConfigData)
local RoadCreationOutputData = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.RoadCreationOutputData)
local CreateTypeEnums = require(ReplicatedStorage.RoadBuilder.RoadBuilderEnums.CreateTypeEnums)
local RoadTypeEnums = require(ReplicatedStorage.RoadBuilder.RoadBuilderEnums.RoadTypeEnums)
local RoadBuilderAssetGetter = require(ReplicatedStorage.RoadBuilder.RoadBuilderAssetGetter)
local RoadCreationConfig = require(ReplicatedStorage.RoadBuilder.RoadBuilderConfig.RoadCreationConfig)
local DependentPointConfig = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.CacheDataWrappers.PointConfigWrappers.DependentPointConfig)
local EndPointConfig = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.CacheDataWrappers.PointConfigWrappers.EndPointConfig)
local DefaultCreateType = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.CreatePropertyWrappers.DefaultCreateType)
local ExtensionConfigData = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.ExtensionConfigData)
local ClearPreviousRoad = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.OverrideRoadWrappers.ClearPreviousRoad)
local SetPointCacheType = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.OverrideRoadWrappers.SetPointCacheType)
local CreateVariantEnums = require(ReplicatedStorage.RoadBuilder.RoadBuilderEnums.CreateVariantEnums)
local OverrideRoadEnums = require(ReplicatedStorage.RoadBuilder.RoadBuilderEnums.OverrideRoadEnums)
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
end

local function assertCreateDefaultTypeToServer(defaultCreateType: DefaultCreateType.DefaultCreateType): boolean
	local isCreateTypeDefault = (defaultCreateType.tag == CreateTypeEnums.Default)
	if isCreateTypeDefault then
		assert(RunService:IsServer(), "Passing `CreateTypeEnums.Default` can only be done on the server")
	end

	return isCreateTypeDefault
end

--TODO: support an else for this one
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
	createVariant: CreateVariantEnums.CreateVariantEnums,
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
		RoadBuilderCache.SetRoadPointCache(
			newRoadPoint, 
			RoadPointCache(
				shouldBeCachedAsEndPoint and RoadPointCacheTypeEnums.EndPoint or RoadPointCacheTypeEnums.DependentPoint,
				shouldBeCachedAsEndPoint 
					and EndPointConfig(
						{},
						{},
						{},
						{}
					)
					or DependentPointConfig(
						{},
						{}
					),

				RoadCreationConfig.DEFAULT_ROAD_POINT_AXIS
			)
		)
	end)

	return newRoadPoint, VectorUtils.Vector2FromVector3(newRoadPoint.Position)
end

local function createRoad(
	roadAsset: BasePart, 

	roadConfig: RoadConfigData.RoadConfigData,
	createVariant: CreateVariantEnums.CreateVariantEnums,
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
				{},
				{}
			)
		)
	end)

	return newRoad
end

-- merges both createRoad() and createRoadPoint()
local function createRoadExtension(
	roadPointAsset: BasePart,
	roadAsset: BasePart,

	roadConfig: RoadConfigData.RoadConfigData,
	createVariant: CreateVariantEnums.CreateVariantEnums,

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
			createVariant,
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
				createVariant,
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

			goalRoadPointCache = RoadBuilderCache.GetRoadPointCache(goalRoadPoint)
			goalRoadPointCache.vector2Direction = newRoadToGoalDirection
		end
		
		return goalRoadPoint, originToGoalRoad, goalVector2Direction

	-- visualize (no care about caching here, just make road extensions)
	else
		local newRoadPoint = createRoadPoint(
			roadPointAsset,
			roadConfig,
			createVariant,
			roadConfig.createType.parent,
			toExtensionData,
			fromExtenstionData
		)
		local newRoad = createRoad(
			roadAsset, 
			roadConfig,
			createVariant,
			roadConfig.createType.parent,
			fromExtenstionData,
			toExtensionData
		)

		return newRoadPoint, newRoad 
	end
end

local function cacheEndPointData(
	originRoadPoint: BasePart,
	goalRoadPoint: BasePart,

	dependentRoadPoints: {BasePart},
	dependentRoads: {BasePart}
)
	local endPoints = {
		originRoadPoint = {
			roadPointInstance = originRoadPoint;
			roadPointCache = RoadBuilderCache.GetRoadPointCache(originRoadPoint);
		};
		goalRoadPoint = {
			roadPointInstance = goalRoadPoint;
			roadPointCache = RoadBuilderCache.GetRoadPointCache(goalRoadPoint);
		};
	}

	for _, endPoint in 
		endPoints:: {{roadPointInstance: BasePart, roadPointCache: RoadPointCache.RoadPointCache}}
	do
		local endPointCache: RoadPointCache.RoadPointCache = endPoint.roadPointCache
		if endPointCache.roadPointCacheType == RoadPointCacheTypeEnums.DependentPoint then
			continue
		end

		local endPointRoadConfig: EndPointConfig.EndPointConfig = endPointCache.roadPointConfig

		local endPointInstance = endPoint.roadPointInstance
		local otherEndPointInstance = endPointInstance == originRoadPoint 
			and goalRoadPoint
			or originRoadPoint

		for _, dependentRoadPoint in dependentRoadPoints do
			table.insert(endPointRoadConfig.dependentRoadInstances.roadPoints, dependentRoadPoint)

			local dependentRoadPointCache = RoadBuilderCache.GetRoadPointCache(dependentRoadPoint)
			if dependentRoadPointCache then
				local roadConfig: DependentPointConfig.DependentPointConfig = dependentRoadPointCache.roadPointConfig
				table.insert(roadConfig.dependeeRoadPoints, endPointInstance)
			end
		end
		for _, dependentRoad in dependentRoads do
			table.insert(endPointRoadConfig.dependentRoadInstances.roads, dependentRoad)

			local dependentRoadCache = RoadBuilderCache.GetRoadCache(dependentRoad)
			if dependentRoadCache then
				table.insert(dependentRoadCache.dependeeRoadPoints, endPointInstance)
			end
		end

		table.insert(endPointRoadConfig.pairExtensionEndRoadPoints, otherEndPointInstance)
	end

	RoadBuilderCache.QueueReplicationCache(
		originRoadPoint,
		endPoints.originRoadPoint.roadPointCache,
		RoadBuilderCache.TARGET_CACHE_TYPE_ENUMS.TargetRoadPoint
	)
	RoadBuilderCache.QueueReplicationCache(
		goalRoadPoint,
		endPoints.goalRoadPoint.roadPointCache,
		RoadBuilderCache.TARGET_CACHE_TYPE_ENUMS.TargetRoadPoint
	)
end

local function cacheRoadAndRoadPointData(
	fromPointInstance: BasePart,
	toPointInstance: BasePart,
	roadInstance: BasePart
)
	local fromPointCache = RoadBuilderCache.GetRoadPointCache(fromPointInstance)
	local toPointCache = RoadBuilderCache.GetRoadPointCache(toPointInstance)
	local roadCache = RoadBuilderCache.GetRoadCache(roadInstance)

	-- update roadpoint cache
	table.insert(fromPointCache.roadPointConfig.connectedRoads, roadInstance)
	RoadBuilderCache.QueueReplicationCache(
		fromPointInstance,
		fromPointCache,
		RoadBuilderCache.TARGET_CACHE_TYPE_ENUMS.TargetRoadPoint
	)

	table.insert(toPointCache.roadPointConfig.connectedRoads, roadInstance)
	RoadBuilderCache.QueueReplicationCache(
		toPointInstance,
		toPointCache,
		RoadBuilderCache.TARGET_CACHE_TYPE_ENUMS.TargetRoadPoint
	)

	-- update road cache
	table.insert(roadCache.connectedRoadPoints, fromPointInstance)
	table.insert(roadCache.connectedRoadPoints, toPointInstance)
	RoadBuilderCache.QueueReplicationCache(
		roadInstance,
		roadCache,
		RoadBuilderCache.TARGET_CACHE_TYPE_ENUMS.TargetRoad
	)
end

local function clearPreviousRoadOverride(clearPreviousRoadConfig: ClearPreviousRoad.ClearPreviousRoad)
	assert(clearPreviousRoadConfig, "Cannot override previous road with nil `clearPreviousRoadConfig`")

    for _, clearPosition in clearPreviousRoadConfig.clearPointPositions do
		--[[
			this refers to the `currentRemakeRoadCache.selectionRoadPoint.Position` from RoadBuilderClient.luau
			ps. we're sending positions instead of instances to avoid issues from the client-server boundary
		]]
		local previousRoadPoint = RoadBuilderCache.GetRoadInstanceFromVector3(clearPosition)

		local previousRoadPointCache = previousRoadPoint and RoadBuilderCache.GetRoadPointCache(previousRoadPoint)
		if not previousRoadPointCache or previousRoadPointCache.roadPointCacheType == RoadPointCacheTypeEnums.DependentPoint then
			continue
		end

		local previousRoadPointConfig = previousRoadPointCache.roadPointConfig

		-- override via Destroy()
		for _, roadInstance in TableUtils.MergeArray(
			previousRoadPointConfig.dependentRoadInstances.roadPoints,
			previousRoadPointConfig.dependentRoadInstances.roads,
			previousRoadPoint
		) do
			roadInstance:Destroy()
		end

		for _, endPoint in previousRoadPointConfig.pairExtensionEndRoadPoints do
			local endPointCache = RoadBuilderCache.GetRoadPointCache(endPoint)
			if not endPointCache or endPointCache.roadPointCacheType == RoadPointCacheTypeEnums.DependentPoint then
				continue
			end

			local endPointRoadConfig = endPointCache.roadPointConfig

			local previousIndexInCache = table.find(
				endPointRoadConfig.pairExtensionEndRoadPoints,
				previousRoadPoint
			)
			if previousIndexInCache then
				table.remove(endPointRoadConfig.pairExtensionEndRoadPoints, previousIndexInCache)
			end
		end

		RoadBuilderCache.ClearRoadPointCache(previousRoadPoint)
    end
end

local function setPointCacheTypeOverride(setPointCacheType: SetPointCacheType.SetPointCacheType)
	assert(setPointCacheType, "Cannot set point cache type with nil `setPointCacheType`")

	for _, targetPosition in setPointCacheType.pointPositions do
		local targetPointInstance = RoadBuilderCache.GetRoadInstanceFromVector3(targetPosition)
		local targetPointCache = targetPointInstance
			and RoadBuilderCache.GetRoadPointCache(targetPointInstance)
		
		-- no changes necessary
		if 
			not targetPointCache 
			or targetPointCache.roadPointCacheType == setPointCacheType.pointCacheType 
		then
			continue
		end
		
		-- converting cache type `DependentPoint` to `EndPoint`
		if setPointCacheType.pointCacheType == RoadPointCacheTypeEnums.EndPoint then
			local targetPointConfig: DependentPointConfig.DependentPointConfig = targetPointCache.roadPointConfig
			
			-- contains endpoints paired to target endpoint
			local pairEndPointDataList = {}:: {
				[BasePart]: {
					dependentRoadPoints: {BasePart};
					dependentRoads: {BasePart};
					pointCache: RoadPointCache.RoadPointCache;
				}
			}
			local intersectedRoadDependents: {BasePart} = {}

			for _, connectedRoadInstance in targetPointConfig.connectedRoads do
				local previousInstance = targetPointInstance
				local currentRoadInstance = connectedRoadInstance
				local currentRoadCache = RoadBuilderCache.GetRoadDataFromVector3(connectedRoadInstance.Position)

				local connectedRoadPoints = {}
				local connectedRoads = {connectedRoadInstance}

				--[[
					FILL IN `newDependentRoadPoints` AND `newDependentRoads`
				]]

				while (currentRoadCache.roadPointCacheType ~= RoadPointCacheTypeEnums.EndPoint) do
					local nextConnectedList: {BasePart} = 
						currentRoadCache.roadPointConfig
						and currentRoadCache.roadPointConfig.connectedRoads

						or currentRoadCache.connectedRoadPoints
					
					table.insert(intersectedRoadDependents, currentRoadInstance)

					local toBePreviousInstance = currentRoadInstance

					for _, nextConnectedInstance in nextConnectedList do
						if nextConnectedInstance == previousInstance then
							continue
						end

						local nextConnectedCache = RoadBuilderCache.GetRoadDataFromVector3(nextConnectedInstance.Position)

						currentRoadInstance = nextConnectedInstance
						currentRoadCache = nextConnectedCache

						if currentRoadCache.roadPointCacheType ~= RoadPointCacheTypeEnums.EndPoint then
							if currentRoadCache.roadVariant == RoadVariantEnums.RoadPoint then
								table.insert(connectedRoadPoints, nextConnectedInstance)
							else
								table.insert(connectedRoads, nextConnectedInstance)
							end
							table.insert(intersectedRoadDependents, nextConnectedInstance)
						end
					end

					-- avoid infinite recursion, just incase ig
					if currentRoadInstance == toBePreviousInstance then
						break
					end

					previousInstance = toBePreviousInstance
				end

				--[[
					FILL IN `endPointData`
				]]

				-- now we can assume that `currentRoadInstance` is an endpoint
				pairEndPointDataList[currentRoadInstance] = {
					dependentRoadPoints = connectedRoadPoints;
					dependentRoads = connectedRoads;
					pointCache = currentRoadCache;
				}
			end

			for pairEndPointInstance, pairEndPointData in pairEndPointDataList do
				local pairEndPointRoadCache: RoadPointCache.RoadPointCache = pairEndPointData.pointCache
				local pairEndPointRoadConfig: EndPointConfig.EndPointConfig = pairEndPointRoadCache.roadPointConfig

				-- remove all previous roads between the end points
				for _, intersectedRoad in intersectedRoadDependents do
					local intersectedtoDependentRoadPointIndex = table.find(
						pairEndPointRoadConfig.dependentRoadInstances.roadPoints,
						intersectedRoad
					)
					local intersectedtoDependentRoadIndex = table.find(
						pairEndPointRoadConfig.dependentRoadInstances.roads,
						intersectedRoad
					)

					if intersectedtoDependentRoadPointIndex then
						table.remove(
							pairEndPointRoadConfig.dependentRoadInstances.roadPoints, 
							intersectedtoDependentRoadPointIndex
						)
					elseif intersectedtoDependentRoadIndex then
						table.remove(
							pairEndPointRoadConfig.dependentRoadInstances.roads, 
							intersectedtoDependentRoadIndex
						)
					end
				end
				-- remove target endpoint from `pairEndPointRoadConfig.dependentRoadInstances.roadPoints`
				table.remove(
					pairEndPointRoadConfig.dependentRoadInstances.roadPoints,
					table.find(
						pairEndPointRoadConfig.dependentRoadInstances.roadPoints,
						targetPointInstance
					)
				)

				-- insert the respective split of dependent roads between each of the end points
				TableUtils.InsertValues(pairEndPointRoadConfig.dependentRoadInstances.roadPoints, pairEndPointData.dependentRoadPoints)
				TableUtils.InsertValues(pairEndPointRoadConfig.dependentRoadInstances.roads, pairEndPointData.dependentRoads)

				-- remove the other road points from `pairExtensionEndRoadPoints`
				for otherPointInstance in pairEndPointDataList do
					local otherPointInEndPoints = table.find(pairEndPointRoadConfig.pairExtensionEndRoadPoints, otherPointInstance)
					if not otherPointInEndPoints then
						continue
					end

					table.remove(pairEndPointRoadConfig.pairExtensionEndRoadPoints, otherPointInEndPoints)
				end
				-- insert the new road point into `pairExtensionEndRoadPoints`
				table.insert(pairEndPointRoadConfig.pairExtensionEndRoadPoints, targetPointInstance)

				-- finally.. cache the pair extension endpoints
				RoadBuilderCache.QueueReplicationCache(
					pairEndPointInstance,
					pairEndPointRoadCache,
					RoadBuilderCache.TARGET_CACHE_TYPE_ENUMS.TargetRoadPoint
				)
			end

			--[[
				CACHE TARGET/SELECTION ROADPOINT
			]]

			local targetPairExtensionEndRoadPoints: {BasePart} = {}
			local targetDependentRoadPoints: {BasePart} = {}
			local targetDependentRoads: {BasePart} = {}
			local targetPointDirection: Vector2

			for pointInstance, pointData in pairEndPointDataList do
				local pointVector2Direction = pointData.pointCache.vector2Direction

				table.insert(targetPairExtensionEndRoadPoints, pointInstance)
				TableUtils.InsertValues(targetDependentRoadPoints, pointData.dependentRoadPoints)
				TableUtils.InsertValues(targetDependentRoads, pointData.dependentRoads)

				if not targetPointDirection then
					targetPointDirection = pointVector2Direction
				else
					local dotSign = math.sign(targetPointDirection:Dot(pointVector2Direction))
					targetPointDirection = targetPointDirection:Lerp(pointVector2Direction * dotSign, .5)
				end
			end

			-- cache the targetPointInstance
			RoadBuilderCache.SetRoadPointCache(
				targetPointInstance,
				RoadPointCache( --TODO: update the direction vectorDirection
					RoadPointCacheTypeEnums.EndPoint,
					EndPointConfig(
						targetPairExtensionEndRoadPoints,
						targetDependentRoadPoints,
						targetDependentRoads,
						targetPointCache.roadPointConfig.connectedRoads -- still the same
					),
					targetPointDirection
				)
			)

		-- converting cache type `EndPoint` to `DependentPoint`
		else
			local targetPointConfig: EndPointConfig.EndPointConfig = targetPointCache.roadPointConfig
			
			-- cache the targetPointInstance
			RoadBuilderCache.SetRoadPointCache(
				targetPointInstance,
				RoadPointCache(
					RoadPointCacheTypeEnums.DependentPoint,
					DependentPointConfig(
						targetPointConfig.pairExtensionEndRoadPoints,
						targetPointConfig.connectedRoads
					)
				)
			)
		end
	end
end

--// PUBLIC

local OVERRIDE_CONFIG_TO_FUNCTION = {
	[OverrideRoadEnums.ClearPreviousRoadOverride] = clearPreviousRoadOverride;
	[OverrideRoadEnums.SetPointCacheType] = setPointCacheTypeOverride;
}

--[[
	Applies override road configs, dependent on whatever type is sent through `overrideRoadConfig`.
		
	* ClearPreviousRoad - clears the previous road, used for road remake requests
	* SetPointCacheType - can override a road point's cache type between either DependentPoint and EndPoint
]]
function Creation.ApplyOverrideRoadConfig(
	overrideRoadConfig: ClearPreviousRoad.ClearPreviousRoad | SetPointCacheType.SetPointCacheType
)
	if not overrideRoadConfig then
		return
	end

	local overrideFunction = OVERRIDE_CONFIG_TO_FUNCTION[overrideRoadConfig.tag]
	if overrideFunction then
		overrideFunction(overrideRoadConfig)
	end
end

--[[
	Creates a road origin, needs only origin PointVector2Data. Direction is not forced if left as empty.

	Vector3 Y Level defaults to `originVector2Data.yLevel`, but you can override with `overrideYLevel`
]]
function Creation.CreateOriginRoadPoint(
	roadConfig: RoadConfigData.RoadConfigData,

	originVector2Data: PointVector2Data.PointVector2Data,
	shouldBeCachedAsEndPoint: boolean?
): RoadCreationOutputData.RoadCreationOutputData
	local overrideRoadConfig = roadConfig.overrideRoadConfig
	local roadType = roadConfig.roadType
	local createType = roadConfig.createType
	local isCreateTypeDefault = assertCreateDefaultTypeToServer(createType)

	local ROAD_POINT_ASSET = ASSETS.roadPoint[roadType]

	local newRoadPoint = createRoadPoint(
		ROAD_POINT_ASSET,
		roadConfig,
		CreateVariantEnums.RoadPoint,
		isCreateTypeDefault
			and RoadCreationConfig.ROAD_PARENTS.roadPoint
			or roadConfig.createType.parent,
		originVector2Data,
		nil, 
		shouldBeCachedAsEndPoint
	)

	ifCreateTypeDefault(roadConfig, function()
		-- batch send replication (to client)
		RoadBuilderCache.SendBatchedReplicationCache()
	end)
	
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
	local overrideRoadConfig = roadConfig.overrideRoadConfig
	local originVector2DataWithDir = RoadCreationConfig.ApplyDefaultDirectionToVector2Data(originVector2Data)

	local roadType = roadConfig.roadType
	local createType = roadConfig.createType
	assertCreateDefaultTypeToServer(createType)

	local originPosition = originVector2DataWithDir.position
	local originDirection = originVector2DataWithDir.direction
	local originYLevel = originVector2DataWithDir.yLevel

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

	-- both of these are for different purposes, and are updated everytime a new road is created
	local createdRoadPairs = {}:: {{fromPoint: BasePart, toPoint: BasePart, road: BasePart}} -- for caching purposes
	local dependentRoads = {
		roadPoints = {};
		roads = {};
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
			CreateVariantEnums.RoadExtension,

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

		ifCreateTypeDefault(roadConfig, function()
			local newestRoadPair = createdRoadPairs[#createdRoadPairs]

			table.insert(createdRoadPairs, {
				fromPoint = newestRoadPair 
					and newestRoadPair.toPoint
					or originRoadPoint;
				toPoint = newRoadPoint;
				road = newRoad;
			})
		end)

		previousRoadPointPosition = curvePosition
		previousRoadPointT = verticalT
		previousRoadPointYLevel = math.lerp(originYLevel, goalYLevel, verticalT)
	end

	-- make final road directly on "goalPosition"
	local goalRoadPoint, goalRoad, goalDirection = createRoadExtension(
		ROAD_POINT_ASSET,
		ROAD_ASSET,

		roadConfig,
		CreateVariantEnums.RoadExtension,

		PointVector2Data(previousRoadPointPosition, nil, previousRoadPointYLevel),
		PointVector2Data(goalPosition, nil, goalYLevel),
		ExtensionConfigData(
			true
		)
	)
	-- we dont include `goalRoadPoint` because thatll be the `goalRoadPoint` for extension data
	table.insert(dependentRoads.roads, goalRoad)

	ifCreateTypeDefault(roadConfig, function()
		--[[
			should be ran before any of the new extension road data is cached
			movitation is that its easier to modify/override "previous road data" so to speak
		]]
		-- Creation.ApplyOverrideRoadConfig(overrideRoadConfig)

		do 
			local newestRoadPair = createdRoadPairs[#createdRoadPairs]
		
			-- insert final goal road pairs
			table.insert(createdRoadPairs, {
				fromPoint = newestRoadPair 
					and newestRoadPair.toPoint
					or originRoadPoint;
				toPoint = goalRoadPoint;
				road = goalRoad
			})
		end

		-- cache road pairs
		for _, roadPair in createdRoadPairs do
			cacheRoadAndRoadPointData(roadPair.fromPoint, roadPair.toPoint, roadPair.road)
		end

		-- update server cache extension road data
		cacheEndPointData(
			originRoadPoint,
			goalRoadPoint,
	
			dependentRoads.roadPoints,
			dependentRoads.roads
		)

		-- Creation.ApplyOverrideRoadConfig(overrideRoadConfig)

		-- send all batched replication data (to client)
		RoadBuilderCache.SendBatchedReplicationCache()
	end)
	
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
	