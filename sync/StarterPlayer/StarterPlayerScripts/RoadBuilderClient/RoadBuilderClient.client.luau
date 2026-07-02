local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")

local RoadBuilderCache = require(ReplicatedStorage.RoadBuilder.RoadBuilderCache)
local RoadCreationConfig = require(ReplicatedStorage.RoadBuilder.RoadBuilderConfig.RoadCreationConfig)
local EndPointConfig = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.CacheDataWrappers.PointConfigWrappers.EndPointConfig)
local RoadPointCache = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.CacheDataWrappers.RoadPointCache)
local CreateRoadRequestConfig = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.CreateRoadWrappers.CreateRoadRequestConfig)
local ClearPreviousRoad = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.OverrideRoadWrappers.ClearPreviousRoad)
local SetPointCacheType = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.OverrideRoadWrappers.SetPointCacheType)
local PointVector2Data = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.PointVector2Data)
local CreateVariantEnums = require(ReplicatedStorage.RoadBuilder.RoadBuilderEnums.CreateVariantEnums)
local RoadPointCacheTypeEnums = require(ReplicatedStorage.RoadBuilder.RoadBuilderEnums.RoadPointCacheTypeEnums)
local RoadVariantEnums = require(ReplicatedStorage.RoadBuilder.RoadBuilderEnums.RoadVariantEnums)
local MouseUtils = require(StarterPlayer.StarterPlayerScripts.ClientUtils.MouseUtils)
local RoadBuilderEvents = require(ReplicatedStorage.RoadBuilder.RoadBuilderEvents)
local RoadBuilderSelectionValidator = require(ReplicatedStorage.RoadBuilder.RoadBuilderUtils.RoadBuilderSelectionValidator)
local Janitor = require(ReplicatedStorage.SharedPackages.Janitor)
local Vide = require(ReplicatedStorage.SharedPackages.Vide)
local VectorUtils = require(ReplicatedStorage.SharedUtils.VectorUtils)
local InputManager = require(StarterPlayer.StarterPlayerScripts.Inputs.InputManager)
local RoadVisualizationConfig = require(StarterPlayer.StarterPlayerScripts.RoadBuilderClient.RoadBuilderConfig.RoadVisualizationConfig)
local RoadExtensionVisualData = require(StarterPlayer.StarterPlayerScripts.RoadBuilderClient.RoadBuilderDataWrappers.VisualizationWrappers.RoadExtensionVisualData)
local PointHighlightEnums = require(StarterPlayer.StarterPlayerScripts.RoadBuilderClient.RoadBuilderEnums.PointHighlightEnums)
local RemakeTypeEnums = require(StarterPlayer.StarterPlayerScripts.RoadBuilderClient.RoadBuilderEnums.RemakeTypeEnums)
local RoadBuilderState = require(StarterPlayer.StarterPlayerScripts.RoadBuilderClient.RoadBuilderState)
local RoadBuilderErrorAlert = require(StarterPlayer.StarterPlayerScripts.RoadBuilderClient.RoadBuilderUtils.RoadBuilderErrorAlert)
local RoadPointHighlight = require(StarterPlayer.StarterPlayerScripts.RoadBuilderClient.RoadBuilderUtils.RoadBuilderInstanceHighlights.RoadPointHighlight)
local RoadBuilderSelectionPrompt = require(StarterPlayer.StarterPlayerScripts.RoadBuilderClient.RoadBuilderUtils.RoadBuilderSelectionPrompt)
local RoadBuilderVisualization = require(StarterPlayer.StarterPlayerScripts.RoadBuilderClient.RoadBuilderUtils.RoadBuilderVisualization)

type RemakeState = {
	isRemaking: boolean;
	remakeType: RemakeTypeEnums.RemakeTypeEnums?;

	wasEverRemaked: boolean;
}
type RemakeRoadData = {
	roadInstance: BasePart;
	roadVariant: RoadVariantEnums.RoadVariantEnums;
	roadColor: Color3;
}
type RemakeEndPointData = {
	creationDirection: Vector2;

	curvingToGoalDirection: Vector2;
	validityDirection: Vector2;
}

local SELECTION_GUI, SELECTION_GUI_SIGNALS, SELECTION_GUI_DESTRUCTOR = RoadBuilderSelectionPrompt.CreateSelectionPrompt()
local DEFAULT_REMAKE_STATE: RemakeState = {
	isRemaking = false;
	remakeType = nil;
	wasEverRemaked = nil;
}

local camera = workspace.CurrentCamera
local states = RoadBuilderState.GetStates()

-- ONPRESS INPUT (placing a road)
local onPressJanitor = Janitor.new()
local onPressDebounce = false

-- road visualization
local renderThrottle: number = 0

local currentRemakeRoadCache = {
	--[[
		`isRemaking` is merely a debounce for repositioning/remaking actions

		`wasRemaked` keeps track of any kind of positional change after the first "selection onpress", 
		implies a remake
	]]
	remakeState = {
		isRemaking = DEFAULT_REMAKE_STATE.isRemaking;
		remakeType = DEFAULT_REMAKE_STATE.remakeType;

		wasEverRemaked = DEFAULT_REMAKE_STATE.wasEverRemaked;
	}:: RemakeState;

	--[[
		this section is only non nil/empty IF the remaked road is existent (rather than just remaking a simulation)
	]]
	selectionRoadPoint = nil:: BasePart?;
	dependentRoads = {}:: {RemakeRoadData?};
	nRoads = 0:: number;
	endRoadPoints = {}:: RemakeEndPointData;
}

local function newRoadPointOnMouse(positionBackup: Vector3?): (BasePart, () -> ())
	local mouseCast = MouseUtils.GetMouseCast()

	local mousePosition = mouseCast and mouseCast.Position or positionBackup
	local mouseRoadVisualData = RoadBuilderVisualization.VisualizeRoadPoint(
		RoadBuilderState.CurrentRoadType(),
		RoadVisualizationConfig.VISUALIZER_ROAD_CREATE_TYPES.default(),

		PointVector2Data(mousePosition)
	)

	return mouseRoadVisualData.roadPointInstance, mouseRoadVisualData.destructor
end

--[[
	SELECTION GUI
]]

local function toggleFinalizedSelectionGui(isFinalizing: boolean)
	SELECTION_GUI.gui.Enabled = isFinalizing
end

local function attachSelectionGui(adornee: Instance)
	SELECTION_GUI.gui.Adornee = adornee
	if not adornee then
		SELECTION_GUI.gui.Enabled = false
	end
end

--[[
	REMAKE CACHE
]]

local function resetRemakeState()
	currentRemakeRoadCache.remakeState.isRemaking = DEFAULT_REMAKE_STATE.isRemaking
	currentRemakeRoadCache.remakeState.remakeType = DEFAULT_REMAKE_STATE.remakeType
	currentRemakeRoadCache.remakeState.wasEverRemaked = DEFAULT_REMAKE_STATE.wasEverRemaked
end

local function updateRemakingStatus(
	isRemaking: boolean,
	remakeType: RemakeTypeEnums.RemakeTypeEnums?
)
	currentRemakeRoadCache.remakeState.isRemaking = isRemaking
	currentRemakeRoadCache.remakeState.remakeType = remakeType
end

local function setWasEverRemaked(wasRemaked: boolean)
	currentRemakeRoadCache.remakeState.wasEverRemaked = wasRemaked
end

local function resetRemakeRoadCache()
	table.clear(currentRemakeRoadCache.dependentRoads)
	table.clear(currentRemakeRoadCache.endRoadPoints)
	currentRemakeRoadCache.selectionRoadPoint = nil
	currentRemakeRoadCache.nRoads = 0

	resetRemakeState()
end

local function cacheRemakeRoads(capturedStates: RoadBuilderState.CapturedStates): boolean?
	local goalPoint = capturedStates.currentGoalPoint.goalPoint
	local goalPointPosition = goalPoint.Position
	local goalPointPosition2D = VectorUtils.Vector2FromVector3(goalPointPosition)

	-- check if current goalpoint has any cache, otherwise return
	local goalPointCache: RoadPointCache.RoadPointCache = RoadBuilderCache.GetRoadDataFromVector3(goalPointPosition)
	if 
		not goalPointCache 
		or goalPointCache.roadPointCacheType == RoadPointCacheTypeEnums.DependentPoint 
	then
		return
	end

	local goalPointRoadConfig: EndPointConfig.EndPointConfig = goalPointCache.roadPointConfig
	--[[
		insert dependent roads / roadpoints of cac`goalPointRoadConfig into `currentRemakeRoadCache.dependentRoads`
	]]
	for _, roadInstance in goalPointRoadConfig.dependentRoadInstances.roadPoints do
		table.insert(currentRemakeRoadCache.dependentRoads, {
			roadInstance = roadInstance;
			roadVariant = RoadVariantEnums.RoadPoint;
			roadColor = roadInstance.Color;
		})
	end
	for _, roadInstance in goalPointRoadConfig.dependentRoadInstances.roads do
		table.insert(currentRemakeRoadCache.dependentRoads, {
			roadInstance = roadInstance;
			roadVariant = RoadVariantEnums.Road;
			roadColor = roadInstance.Color;
		})
	end

	-- used for serverside override data
	currentRemakeRoadCache.selectionRoadPoint = capturedStates.currentGoalPoint.referenceInstance

	-- loop through road points, and ensure that direction data is reflected for visualization accuracy
	for _, endRoadPoint in goalPointRoadConfig.pairExtensionEndRoadPoints do
		local endRoadPointCache: RoadPointCache.RoadPointCache = RoadBuilderCache.GetRoadDataFromVector3(endRoadPoint.Position)
		if not endRoadPointCache then
			continue
		end

		local endRoadPointPosition2D = VectorUtils.Vector2FromVector3(endRoadPoint.Position)
		local endToGoalDirection = (endRoadPointPosition2D - goalPointPosition2D).Unit
		local curvingToGoalDirection = Vector2.new(endToGoalDirection.Y, -endToGoalDirection.X)
		
		currentRemakeRoadCache.endRoadPoints[endRoadPoint] = {
			creationDirection = endRoadPointCache.vector2Direction;
			curvingToGoalDirection = curvingToGoalDirection;
			validityDirection = endToGoalDirection;
		}
		currentRemakeRoadCache.nRoads += 1
	end
end

local function toggleRemakeRoadsCache(isVisible: boolean)
	if currentRemakeRoadCache.selectionRoadPoint then
		RoadBuilderVisualization.ApplyVisualizeCreateTypeProperties(
			currentRemakeRoadCache.selectionRoadPoint,
			RoadVariantEnums.RoadPoint,
			isVisible
			and RoadVisualizationConfig.VISUALIZER_ROAD_CREATE_TYPES.default(true)
			or RoadVisualizationConfig.VISUALIZER_ROAD_CREATE_TYPES.remake
		)
	end
	for _, remakeRoadData in currentRemakeRoadCache.dependentRoads do
		local isRoadPoint = (remakeRoadData.roadVariant == RoadVariantEnums.RoadPoint)

		if isVisible then
			remakeRoadData.roadInstance.Color = remakeRoadData.roadColor

			RoadBuilderVisualization.ApplyVisualizeCreateTypeProperties(
				remakeRoadData.roadInstance,
				remakeRoadData.roadVariant,
				RoadVisualizationConfig.VISUALIZER_ROAD_CREATE_TYPES.default(isRoadPoint)
			)
		else
			RoadBuilderVisualization.ApplyVisualizeCreateTypeProperties(
				remakeRoadData.roadInstance,
				remakeRoadData.roadVariant,
				RoadVisualizationConfig.VISUALIZER_ROAD_CREATE_TYPES.remake
			)
		end
	end
end

local function getAppropriateEndPointDirection(endData: RemakeEndPointData): Vector2
	local isSingleRoad = (currentRemakeRoadCache.nRoads == 1)

	return isSingleRoad 
		and endData.creationDirection
		or endData.curvingToGoalDirection
end

--[[
	ROAD CREATION
]]

local function visualizeRemakeRoad(capturedStates: RoadBuilderState.CapturedStates): boolean
	local hasInvalid = false

	for endRoadPoint, endData in currentRemakeRoadCache.endRoadPoints do
		local createRoadConfig = CreateRoadRequestConfig(
			capturedStates.currentRoadType,
			CreateVariantEnums.RoadExtension,
			nil, 

			nil, -- to be set
			PointVector2Data(states.currentGoalPoint().goalPoint.Position)
		)

		-- validity check

		createRoadConfig.fromPositionVector2Data = PointVector2Data(
			endRoadPoint.Position, 
			endData.validityDirection or RoadCreationConfig.DEFAULT_ROAD_POINT_AXIS
		)
		local isValid = RoadBuilderSelectionValidator.ValidateRoadRequest(
			createRoadConfig, 
			currentRemakeRoadCache.selectionRoadPoint.Position
		)

		createRoadConfig.fromPositionVector2Data = PointVector2Data(
			endRoadPoint.Position, 
			getAppropriateEndPointDirection(endData)
		)
		RoadBuilderVisualization.VisualizeRoadExtension(
			createRoadConfig.roadType,
			isValid
				and RoadVisualizationConfig.VISUALIZER_ROAD_CREATE_TYPES.default()
				or RoadVisualizationConfig.VISUALIZER_ROAD_CREATE_TYPES.error,

			createRoadConfig.fromPositionVector2Data,
			createRoadConfig.toPositionVector2Data
		)

		if 
			not isValid 
			and not hasInvalid -- debounce
		then
			hasInvalid = true
		end
	end

	return (not hasInvalid) -- if `hasInvalid` is true, return false for "road validity"
end

local function visualizeStandardRoad(capturedStates: RoadBuilderState.CapturedStates): (boolean, RoadExtensionVisualData.RoadExtensionVisualData)
	local createRoadConfig = CreateRoadRequestConfig(
		capturedStates.currentRoadType,
		CreateVariantEnums.RoadExtension,
		nil, 

		PointVector2Data(
			capturedStates.currentSelectionPoint.selectionPoint.Position, 
			capturedStates.currentSelectionPoint.selectionDirection or RoadCreationConfig.DEFAULT_ROAD_POINT_AXIS
		),
		PointVector2Data(states.currentGoalPoint().goalPoint.Position)
	)

	local isValid = RoadBuilderSelectionValidator.ValidateRoadRequest(createRoadConfig)
	local roadCache = RoadBuilderVisualization.VisualizeRoadExtension(
		createRoadConfig.roadType,
		isValid 
				and RoadVisualizationConfig.VISUALIZER_ROAD_CREATE_TYPES.default()
				or RoadVisualizationConfig.VISUALIZER_ROAD_CREATE_TYPES.error,

		createRoadConfig.fromPositionVector2Data,
		createRoadConfig.toPositionVector2Data
	)

	return isValid, roadCache
end

local function requestRoadCreation(createRoadConfig: CreateRoadRequestConfig.CreateRoadRequestConfig)
	RoadBuilderEvents.CreateRoadRequest:FireServer(createRoadConfig)
end

--[[
	SIMULATED ROAD GOALPOINT MOVEMENT
]]

local function moveCurrentGoalPoint(position: Vector3)
	Vide.untrack(states.currentGoalPoint).goalPoint.Position = position
end


--[[
	ONPRESS FUNCTIONS
]]

local function resetRenderThrottle()
	renderThrottle = 0
end

local function refreshCapturedStates(capturedStates: RoadBuilderState.CapturedStates)
	capturedStates = RoadBuilderState.CaptureStates()
end

local function exitFinalizedSelection()
	onPressJanitor:Cleanup()

	-- undo any "remake movement"
	toggleRemakeRoadsCache(true)
	resetRemakeRoadCache()

	-- -- to reset error alerts
	RoadBuilderErrorAlert.ClearErrorAlerts()

	-- to reset selection prompt
	toggleFinalizedSelectionGui(false)
	
	RoadBuilderState.SetMovingSelection(
		false, 
		nil
	)
	states.isPromptedSelection(false)
	states.isValidRoadSelection(true)
	onPressDebounce = false
end

--[[
	acknowledges selection clicks

	when a click is valid, creates a selection gui and its respective signals
	which will be kept until the X button is pressed, destroying the gui and its signals

	and thereby toggling `onPressDebounce` to allow for another selection click
]]
InputManager.OnPress:Connect(function()
	local capturedStates = RoadBuilderState.CaptureStates()

	if 
		onPressDebounce
		or not capturedStates.isInBuildMenu
		or not capturedStates.currentGoalPoint.goalPoint
	then
		return
	end

	local remakeState = currentRemakeRoadCache.remakeState
	local previousVerticalRay = MouseUtils.GetMouseRay()

	onPressDebounce = true

	-- enable selection state, pauses resimulation of clientside roads (sent to the server)
	states.isPromptedSelection(true)

	resetRenderThrottle()
	RoadBuilderState.ResetStates("IsMovingSelection")
	RoadBuilderCache.DestroyAllListeners() -- destroy previous data listeners

	-- prepare remakecache incase of "remake movement"
	resetRemakeRoadCache()
	cacheRemakeRoads(capturedStates)

	--[[
		make the final road visualization (if applicable)
		just to fix up anything that may have been missed from the renderstep
	]]
	if capturedStates.currentSelectionPoint.selectionPoint then
		RoadBuilderVisualization.ClearVisualizedRoads(capturedStates.currentGoalPoint.goalPoint)
		RoadBuilderState.IsValidRoadSelection(visualizeStandardRoad(capturedStates))
	end

	-- selection prompt gui
	toggleFinalizedSelectionGui(true)
	attachSelectionGui(capturedStates.currentGoalPoint.goalPoint)

	--[[
		MOVEMENT SIGNALS
	]]

	-- vertical remake
	onPressJanitor:Add(SELECTION_GUI_SIGNALS.verticalDragContinue:Connect(function()
		if remakeState.isRemaking and remakeState.remakeType ~= RemakeTypeEnums.Vertical then
			return
		end

		refreshCapturedStates(capturedStates)

		local verticalDist = (camera.CFrame.Position - capturedStates.currentGoalPoint.goalPoint.Position).Magnitude
		local currentVerticalRay = MouseUtils.GetMouseRay()
		local verticalDelta = ((currentVerticalRay.Direction.Unit * verticalDist).Y - (previousVerticalRay.Direction.Unit * verticalDist).Y)
		
		RoadBuilderState.SetMovingSelection(
			true,
			states.currentGoalPoint().goalPoint.Position 
			+ Vector3.new(0, verticalDelta * RoadVisualizationConfig.VERTICAL_REMAKE_MULTIPLIER, 0)
		)

		previousVerticalRay = currentVerticalRay
	end))
	onPressJanitor:Add(SELECTION_GUI_SIGNALS.verticalDragStarted:Connect(function()
		if remakeState.isRemaking then
			return
		end
		updateRemakingStatus(
			true,
			RemakeTypeEnums.Vertical
		)
		setWasEverRemaked(true)

		previousVerticalRay = MouseUtils.GetMouseRay()
		toggleRemakeRoadsCache(false)
		RoadBuilderState.SetMovingSelection(true)
	end))
	onPressJanitor:Add(SELECTION_GUI_SIGNALS.verticalDragEnded:Connect(function()
		if remakeState.remakeType ~= RemakeTypeEnums.Vertical then
			return
		end
		updateRemakingStatus(
			false,
			nil
		)

		RoadBuilderState.SetMovingSelection(false)
	end))

	-- freemove remake
	onPressJanitor:Add(SELECTION_GUI_SIGNALS.freemoveStarted:Connect(function()
		if remakeState.isRemaking then
			return
		end
		updateRemakingStatus(
			true,
			RemakeTypeEnums.Freemove
		)
		setWasEverRemaked(true)

		toggleRemakeRoadsCache(false)
		RoadBuilderState.SetMovingSelection(true)
	end))
	onPressJanitor:Add(SELECTION_GUI_SIGNALS.freemoveEnded:Connect(function()
		if remakeState.remakeType ~= RemakeTypeEnums.Freemove then
			return
		end
		updateRemakingStatus(
			false,
			nil
		)

		RoadBuilderState.SetMovingSelection(false)
	end))

	--[[
		CONFIRMATION SIGNALS
	]]

	-- when clicking the "select button"
	onPressJanitor:Add(SELECTION_GUI_SIGNALS.selectTriggered:Once(function()
		refreshCapturedStates(capturedStates)

		--[[
			we avoid making a new road IF the goal roadpoint 
			is the same as the previously selected roadpoint
		]]
		local isRepeatedSelection = false
		--[[
			create NEW ROAD EXTENSION with the newly updated direction state from roadpoint selection
			after each request, the direction state is again reupdated via `requestRoadCreation()`
		]]
		if 
			capturedStates.currentSelectionPoint.selectionPoint
		then
			if 
				capturedStates.currentSelectionPoint.selectionPoint.Position 
				~= capturedStates.currentGoalPoint.goalPoint.Position 
			then
				requestRoadCreation(
					CreateRoadRequestConfig(
						capturedStates.currentRoadType,
						CreateVariantEnums.RoadExtension,
						SetPointCacheType(
							RoadPointCacheTypeEnums.EndPoint,
							{
								-- can be nil
								capturedStates.currentSelectionPoint.selectionPoint and capturedStates.currentSelectionPoint.selectionPoint.Position,
								capturedStates.currentGoalPoint.goalPoint.Position
							}
						),
						
						PointVector2Data(
							capturedStates.currentSelectionPoint.selectionPoint.Position, 
							capturedStates.currentSelectionPoint.selectionDirection
						),
						PointVector2Data(capturedStates.currentGoalPoint.goalPoint.Position)
					)
				)
			else
				isRepeatedSelection = true
			end

		--[[
			otherwise, road point selection/creation, reupdates the direction state
		]]
		else
			if remakeState.wasEverRemaked then
				--[[
					modify EXISTING ROAD EXTENSION (and override old road extension), 
					interacts with `currentRemakeRoadCache` which is modified by "remake movement"
				]]
				for endRoadPoint, endData in currentRemakeRoadCache.endRoadPoints do
					requestRoadCreation(
						CreateRoadRequestConfig(
							capturedStates.currentRoadType,
							CreateVariantEnums.RoadExtension,
							ClearPreviousRoad(
								currentRemakeRoadCache.selectionRoadPoint.Position
							),

							PointVector2Data(
								endRoadPoint.Position, 
								getAppropriateEndPointDirection(endData)
							),
							PointVector2Data(capturedStates.currentGoalPoint.goalPoint.Position)
						)
					)
				end
			else
				local goalRoadPointCache: RoadPointCache.RoadPointCache = RoadBuilderCache.GetRoadDataFromVector3(capturedStates.currentGoalPoint.goalPoint.Position)

				-- if no roadpoint currently in position, create new roadpoint
				if not goalRoadPointCache then
					requestRoadCreation(
						CreateRoadRequestConfig(
							capturedStates.currentRoadType,
							CreateVariantEnums.RoadPoint,
							nil,

							PointVector2Data(capturedStates.currentGoalPoint.goalPoint.Position)
						)
					)
				end
			end
		end

		-- updated selectedroadpoint
		local newSelectionPoint = capturedStates.currentGoalPoint.goalPoint
		RoadBuilderState.SetCurrentSelectionPoint(newSelectionPoint) -- updated current selection
		
		RoadBuilderCache.ListenOnceForVector3(newSelectionPoint.Position, function(
			selectionPointInstance,
			selectionPointData,
			listenDestructor
		)
			-- can be nil if say, a cache update clears the specific `selectionPointInstance` (possibly from an data override)
			if not selectionPointData then
				return 
			end

			RoadBuilderState.SetCurrentSelectionDirection(selectionPointData.vector2Direction) -- update selection direction
			if listenDestructor then
				listenDestructor()
			end
		end)

		-- do not create a new goalpoint if `isRepeatedSelection` is true
		if not isRepeatedSelection then
			local newVisualizedRoadPoint = newRoadPointOnMouse(capturedStates.currentGoalPoint.goalPoint.Position)
			RoadBuilderState.SetCurrentGoalPoint(newVisualizedRoadPoint) -- update current goal
		end

		exitFinalizedSelection()
	end))

	-- when clicking the "undo button"
	onPressJanitor:Add(SELECTION_GUI_SIGNALS.undoTriggered:Once(function()
		-- reset selectedroadpoint
		RoadBuilderState.SetCurrentSelectionPoint(nil)

		exitFinalizedSelection()
	end))
end)

RoadBuilderState.ScopeState(function()
	-- build menu state
	Vide.effect(function()
		local capturedStates = RoadBuilderState.CaptureStates()

		-- if player is in buildmenu, do init data
		if states.isInBuildMenu() then
			onPressDebounce = false

			-- create the endroadpoint ONCE throughout the entire
			local mouseRoadPoint = newRoadPointOnMouse()
			if mouseRoadPoint then
				RoadBuilderState.SetCurrentGoalPoint(mouseRoadPoint)
			end

			toggleFinalizedSelectionGui(false)
			attachSelectionGui(mouseRoadPoint)

		-- if player is no longer in build menu, clear selected road data
		else
			Debris:AddItem(capturedStates.currentGoalPoint.goalPoint)

			onPressJanitor:Cleanup()
			RoadBuilderVisualization.ClearVisualizedRoads()
			RoadBuilderState.ResetStates()
			
			RoadPointHighlight.ResetHighlightAdornees()
			RoadPointHighlight.ResetHighlightTracking()

			attachSelectionGui(nil)
			exitFinalizedSelection()
		end
	end)

	-- error alert + toggle confirmation / valid road selection (in selection prompt)
	Vide.effect(function()
		local capturedStates = RoadBuilderState.CaptureStates()
		-- states.isPromptedSelection() -- track

		if states.isValidRoadSelection() then
			RoadBuilderErrorAlert.ClearErrorAlerts()
			RoadBuilderSelectionPrompt.ToggleValidRoadSelection(SELECTION_GUI, true)
		else
			RoadBuilderErrorAlert.CreateErrorAlert(capturedStates.currentGoalPoint.goalPoint)
			RoadBuilderSelectionPrompt.ToggleValidRoadSelection(SELECTION_GUI, false)
		end
	end)

	-- toggle remake buttons (in selection prompt)
	Vide.effect(function()
		RoadBuilderSelectionPrompt.ToggleRemakeButtons(SELECTION_GUI, states.isSelectingEndPoint())
	end)
end)

local function handleRenderThrottling(capturedStates: RoadBuilderState.CapturedStates)
	-- incase no road is being rendered
	if not capturedStates.currentSelectionPoint.selectionPoint then
		return
	end

	local selectedRoadToMouseDistance = (
		capturedStates.currentSelectionPoint.selectionPoint.Position 
		- states.currentGoalPoint().goalPoint.Position
	).Magnitude
	renderThrottle = 
		selectedRoadToMouseDistance * (
			RoadVisualizationConfig.RENDER_THROTTLE_PER_ROAD_DISTANCE.throttleSeconds 
			/ RoadVisualizationConfig.RENDER_THROTTLE_PER_ROAD_DISTANCE.roadDistance
		)
end

RunService.Heartbeat:Connect(function()
	-- render throttling the visualization code itself (depending on how far the road is from the player)
	if renderThrottle > 0 then
		renderThrottle -= task.wait()
		return
	end

	local capturedStates = RoadBuilderState.CaptureStates()

	if 
		not capturedStates.isInBuildMenu -- is not in build menu?
		or (capturedStates.isPromptedSelection and not capturedStates.isMovingSelection.isMoving) -- is in selection gui?
		or not capturedStates.currentGoalPoint.goalPoint -- should always have a goalpoint at initialization

	-- then, stop rerendering of visualized road
	then
		states.isVisualizing(false)
		return

	-- else, continue with rerendering of visualized road
	else
		--[[
			POSITION/DATA UPDATE PHASE
		]]

		--[[
			position where the simulated/visualized goalpoint is moved to

			first set to `capturedStates.isMovingSelection.overrideMovementPosition`,
			but if nil, then let code below set it
		]]
		local goalPointToPosition: Vector3
		local isRemake = false

		local castData = {
			mouseCast = nil:: RaycastResult?;
			mouseCastPosition = nil:: Vector3?;
			mouseCastInstance = nil:: BasePart?;

			isCastInstanceValidSelection = false:: boolean?;
			isCastEndPoint = true:: boolean?;
		}

		-- override `goalPointToPosition` position (eg vertical movement)
		if capturedStates.isMovingSelection.overrideMovementPosition then
			goalPointToPosition = capturedStates.isMovingSelection.overrideMovementPosition

		-- otherwise, set `goalPointToPosition` to mousecast 
		else
			castData.currentMouseCast = MouseUtils.GetMouseCast()
			if castData.currentMouseCast then
				castData.mouseCastPosition = castData.currentMouseCast.Position
				castData.mouseCastInstance = castData.currentMouseCast.Instance

				local isValidEndPoint
				--[[
					checks if instance has been actually cached, 
					our way of doublechecking if a roadpoint is merely a visualization or not
				]]
				castData.isCastInstanceValidSelection, isValidEndPoint = RoadBuilderSelectionValidator.IsValidRoadPoint(
					castData.mouseCastInstance,
					true
				)
				if castData.isCastInstanceValidSelection then
					castData.isCastEndPoint = isValidEndPoint
				end

				castData.isCastInstanceValidSelection = 
					castData.isCastInstanceValidSelection
					and (castData.mouseCastInstance ~= capturedStates.currentSelectionPoint.selectionPoint)

				local castGoalPosition = castData.isCastInstanceValidSelection
					and castData.mouseCastInstance.Position
					or castData.mouseCastPosition

				goalPointToPosition = castGoalPosition
			end
		end
		
		if 
			capturedStates.isHoveringExistingRoadPoint
			and capturedStates.isMovingSelection.isMoving
			and not capturedStates.currentSelectionPoint.selectionPoint 
		then
			isRemake = true
			castData.isCastEndPoint = true
		else
			states.isHoveringExistingRoadPoint(castData.isCastInstanceValidSelection)

			if castData.isCastInstanceValidSelection then
				-- either existing instance or nil
				RoadBuilderState.SetCurrentGoalReference(castData.mouseCastInstance)
			end
		end

		states.isSelectingEndPoint(castData.isCastEndPoint)

		--[[
			POSITIONING GOALPOINT + REDRAWING ROADS PHASE
		]]

		-- avoid redrawing if its the same goalposition (ie mouse is not moving)
		if capturedStates.previousGoalPosition == goalPointToPosition then
			return
		end

		-- clear current (cached) visualization data, runs destructor functions
		RoadBuilderVisualization.ClearVisualizedRoads(capturedStates.currentGoalPoint.goalPoint)
		RoadPointHighlight.ResetHighlightTracking()

		-- can be nil if player points it to the sky
		if goalPointToPosition then
			moveCurrentGoalPoint(goalPointToPosition)
			states.previousGoalPosition(goalPointToPosition)
		end

		-- remake road simulation
		if isRemake then
			RoadBuilderState.IsValidRoadSelection(visualizeRemakeRoad(capturedStates))
			
		-- standard road simulation
		else
			local updatedGoalPoint = states.currentGoalPoint().goalPoint
			local updatedIsSelectingEndPoint = states.isSelectingEndPoint()

			-- highlight goal point
			if updatedGoalPoint then
				RoadPointHighlight.HighlightRoadPoints(
					states.currentGoalPoint().goalPoint,
					if 
						states.isHoveringExistingRoadPoint()
					then
						updatedIsSelectingEndPoint
						and PointHighlightEnums.EndPointHighlight
						or PointHighlightEnums.DependentPointHighlight
					else
						PointHighlightEnums.NothingHighlight
				)
			end

			if capturedStates.currentSelectionPoint.selectionPoint then
				local isVisualizedRoadValid, visualizedRoadData = visualizeStandardRoad(capturedStates)

				RoadBuilderState.IsValidRoadSelection(isVisualizedRoadValid)
				RoadPointHighlight.HighlightRoadPoints(
					visualizedRoadData.dependentRoadInstances.roadPoints, 
					PointHighlightEnums.DependentPointHighlight
				)
				RoadPointHighlight.HighlightRoadPoints(
					visualizedRoadData.endRoadPointInstance, 
					PointHighlightEnums.EndPointHighlight
				)
			end
		end
		
		-- highlight nearby roadpoints, do spatial partitioning to find said nearby roadpoints
		local roadPointsNearGoalPoint = RoadBuilderCache.RoadInstanceHash.roadPoints:GetHash(capturedStates.currentGoalPoint.goalPoint.Position)
		if roadPointsNearGoalPoint then
			for roadPointInstance: BasePart, roadPointData: RoadPointCache.RoadPointCache in roadPointsNearGoalPoint do
				RoadPointHighlight.HighlightRoadPoints(
					roadPointInstance, 
					roadPointData.roadPointCacheType == RoadPointCacheTypeEnums.EndPoint
						and PointHighlightEnums.EndPointHighlight
						or PointHighlightEnums.DependentPointHighlight
				)
			end	
		end

		handleRenderThrottling(capturedStates)
		states.isVisualizing(true)
	end
end)
