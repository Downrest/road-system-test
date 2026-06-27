local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")

local RoadBuilderCache = require(ReplicatedStorage.RoadBuilder.RoadBuilderCache)
local RoadPointCache = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.CacheDataWrappers.RoadPointCache)
local CreateRoadConfig = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.CreateRoadWrappers.CreateRoadConfig)
local OverrideRoadConfig = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.CreateRoadWrappers.OverrideRoadConfig)
local PointVector2Data = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.PointVector2Data)
local RoadPointCacheTypeEnums = require(ReplicatedStorage.RoadBuilder.RoadBuilderEnums.RoadPointCacheTypeEnums)
local RoadVariantEnums = require(ReplicatedStorage.RoadBuilder.RoadBuilderEnums.RoadVariantEnums)
local MouseUtils = require(StarterPlayer.StarterPlayerScripts.ClientUtils.MouseUtils)
local RoadBuilderEvents = require(ReplicatedStorage.RoadBuilder.RoadBuilderEvents)
local RoadBuilderSelectionValidator = require(ReplicatedStorage.RoadBuilder.RoadBuilderUtils.RoadBuilderSelectionValidator)
local Janitor = require(ReplicatedStorage.SharedPackages.Janitor)
local Vide = require(ReplicatedStorage.SharedPackages.Vide)
local PropertiesUtils = require(ReplicatedStorage.SharedUtils.PropertiesUtils)
local VectorUtils = require(ReplicatedStorage.SharedUtils.VectorUtils)
local InputManager = require(StarterPlayer.StarterPlayerScripts.Inputs.InputManager)
local RoadVisualizationConfig = require(StarterPlayer.StarterPlayerScripts.RoadBuilderClient.RoadBuilderConfig.RoadVisualizationConfig)
local FocusHighlightEnum = require(StarterPlayer.StarterPlayerScripts.RoadBuilderClient.RoadBuilderEnums.FocusHighlightEnum)
local RemakeTypeEnum = require(StarterPlayer.StarterPlayerScripts.RoadBuilderClient.RoadBuilderEnums.RemakeTypeEnum)
local RoadBuilderState = require(StarterPlayer.StarterPlayerScripts.RoadBuilderClient.RoadBuilderState)
local RoadBuilderErrorAlert = require(StarterPlayer.StarterPlayerScripts.RoadBuilderClient.RoadBuilderUtils.RoadBuilderErrorAlert)
local RoadBuilderSelectionPrompt = require(StarterPlayer.StarterPlayerScripts.RoadBuilderClient.RoadBuilderUtils.RoadBuilderSelectionPrompt)
local RoadBuilderVisualization = require(StarterPlayer.StarterPlayerScripts.RoadBuilderClient.RoadBuilderUtils.RoadBuilderVisualization)

type RemakeState = {
	isRemaking: boolean;
	remakeType: RemakeTypeEnum.RemakeTypeEnum?;

	wasEverRemaked: boolean;
}
type RemakeRoadData = {
	roadInstance: BasePart;
	roadColor: Color3;
}

--TODO: do something about this
local BUILD_YIELD_BEFORE_RESIMULATION_RESET = .25
local SELECTION_GUI, SELECTION_GUI_SIGNALS, SELECTION_GUI_DESTRUCTOR = RoadBuilderSelectionPrompt.CreateSelectionPrompt()

local camera = workspace.CurrentCamera
local states = RoadBuilderState.GetStates()

-- ONPRESS INPUT (placing a road)
local onPressJanitor = Janitor.new()
local onPressDebounce = false

-- road visualization
--TODO: moving this into roadbuilderstate lol
local currentMouseCast: RaycastResult
local renderThrottle: number = 0
local currentRemakeRoadCache = {
	dependentRoads = {}:: {RemakeRoadData?};
	selectionRoadPoint = nil:: BasePart?;
	endRoadPoints = {}:: {
		[BasePart]: {
			direction: Vector2
		};
	};
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

local function toggleRemakeRoadsCache(isVisible: boolean)
	for _, remakeRoadData in currentRemakeRoadCache.dependentRoads do
		if isVisible then
			local isSelectionPoint = (remakeRoadData.roadInstance == currentRemakeRoadCache.selectionRoadPoint)

			remakeRoadData.roadInstance.Color = remakeRoadData.roadColor
			--TODO: probably should be an interface within RoadVisualization 100%
			PropertiesUtils.ApplyProperties(
				remakeRoadData.roadInstance,
				RoadVisualizationConfig.VISUALIZER_ROAD_CREATE_TYPES.default(isSelectionPoint).visualizedProperties.road
			)
		else
			PropertiesUtils.ApplyProperties(
				remakeRoadData.roadInstance,
				RoadVisualizationConfig.VISUALIZER_ROAD_CREATE_TYPES.remake.visualizedProperties.road
			)
		end
	end
end

local function clearRemakeRoadsCache()
	for roadIndex in currentRemakeRoadCache.dependentRoads do
		currentRemakeRoadCache.dependentRoads[roadIndex] = nil
	end
	for roadInstance in currentRemakeRoadCache.endRoadPoints do
		currentRemakeRoadCache.endRoadPoints[roadInstance] = nil
	end
	currentRemakeRoadCache.selectionRoadPoint = nil
end

local function cacheRemakeRoads(capturedStates: RoadBuilderState.CapturedStates)
	local goalPoint = capturedStates.currentGoalPoint.goalPoint
	local goalPointPosition = goalPoint.Position
	local goalPointPosition2D = VectorUtils.Vector2FromVector3(goalPointPosition)

	-- check if current goalpoint has any cache, otherwise return
	-- local goalPointCache: RoadPointCache.RoadPointCache = RoadBuilderEvents.RequestRoadData:InvokeServer(goalPointPosition)
	local goalPointCache: RoadPointCache.RoadPointCache = RoadBuilderCache.GetRoadDataFromVector3(goalPointPosition)
	if not goalPointCache then
		return
	end

	local goalDependentRoads = goalPointCache.dependentRoads
	local goalReferenceInstance = capturedStates.currentGoalPoint.referenceInstance

	-- insert dependent roads of cache into `currentRemakeRoadCache.dependentRoads`
	for _, roadInstance in goalDependentRoads do
		table.insert(currentRemakeRoadCache.dependentRoads, {
			roadInstance = roadInstance;
			roadColor = roadInstance.Color;
		})
	end
	-- also insert the goal point reference (only possible if selecing existing roadpoint, which is guaranteed)
	table.insert(currentRemakeRoadCache.dependentRoads, {
		roadInstance = goalReferenceInstance;
		roadColor = goalReferenceInstance.Color;
	})

	-- used for serverside override data
	currentRemakeRoadCache.selectionRoadPoint = capturedStates.currentGoalPoint.referenceInstance

	warn(goalPointCache.pairExtensionEndRoadPoints)

	-- loop through road points, and ensure that direction data is reflected for visualization accuracy
	for _, endRoadPoint in goalPointCache.pairExtensionEndRoadPoints do
		-- local endRoadPointCache: RoadPointCache.RoadPointCache = RoadBuilderEvents.RequestRoadData:InvokeServer(endRoadPoint.Position)
		local endRoadPointCache: RoadPointCache.RoadPointCache = RoadBuilderCache.GetRoadDataFromVector3(endRoadPoint.Position)
		if not endRoadPointCache then
			continue
		end

		local endRoadPointPosition2D = VectorUtils.Vector2FromVector3(endRoadPoint.Position)
		
		--TODO: edit this to be between the endRoadPoint AND the selection point
		currentRemakeRoadCache.endRoadPoints[endRoadPoint] = {
			direction = (endRoadPointPosition2D - goalPointPosition2D).Unit;
		}
	end
end

--[[
	ROAD CREATION
]]

local function visualizeRemakeRoad(capturedStates: RoadBuilderState.CapturedStates): boolean
	local hasInvalid = false

	for endRoadPoint, endData in currentRemakeRoadCache.endRoadPoints do
		endRoadPoint.Color = Color3.new(1, 0, 0)

		local createRoadConfig = CreateRoadConfig(
			capturedStates.currentRoadType,
			RoadVariantEnums.RoadExtension,
			nil, 

			PointVector2Data(
				endRoadPoint.Position, 
				endData.direction
			),
			PointVector2Data(states.currentGoalPoint().goalPoint.Position)
		)

		local isValid = RoadBuilderSelectionValidator.ValidateRoadRequest(createRoadConfig, true)

		--TODO: fix this lol
		-- RoadBuilderVisualization.VisualizeRoadExtension(
		-- 	createRoadConfig.roadType,
		-- 	isValid 
		-- 		and RoadVisualizationConfig.VISUALIZER_ROAD_CREATE_TYPES.remake 
		-- 		or RoadVisualizationConfig.VISUALIZER_ROAD_CREATE_TYPES.error,

		-- 	createRoadConfig.fromPositionVector2Data,
		-- 	createRoadConfig.toPositionVector2Data
		-- )
		RoadBuilderVisualization.VisualizeRoadExtension(
			createRoadConfig.roadType,
			RoadVisualizationConfig.VISUALIZER_ROAD_CREATE_TYPES.default(),

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

local function visualizeStandardRoad(capturedStates: RoadBuilderState.CapturedStates): boolean
	local createRoadConfig = CreateRoadConfig(
		capturedStates.currentRoadType,
		RoadVariantEnums.RoadExtension,
		nil, 

		PointVector2Data(
			capturedStates.currentSelectionPoint.selectionPoint.Position, 
			capturedStates.currentSelectionPoint.selectionDirection
		),
		PointVector2Data(states.currentGoalPoint().goalPoint.Position)
	)

	local isValid = RoadBuilderSelectionValidator.ValidateRoadRequest(createRoadConfig)
	
	RoadBuilderVisualization.VisualizeRoadExtension(
		createRoadConfig.roadType,
		isValid 
				and RoadVisualizationConfig.VISUALIZER_ROAD_CREATE_TYPES.default()
				or RoadVisualizationConfig.VISUALIZER_ROAD_CREATE_TYPES.error,

		createRoadConfig.fromPositionVector2Data,
		createRoadConfig.toPositionVector2Data
	)

	return isValid
end

local function requestRoadCreation(createRoadConfig: CreateRoadConfig.CreateRoadConfig)
	RoadBuilderEvents.CreateRoadRequest:FireServer(createRoadConfig)
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

local function updateRemakingStatus(
	remakeState: RemakeState,
	isRemaking: boolean,
	remakeType: RemakeTypeEnum.RemakeTypeEnum
)
	remakeState.isRemaking = isRemaking
	remakeState.remakeType = remakeType
end

local function exitFinalizedSelection(janitor: Janitor.Janitor)
	janitor:Cleanup()
	toggleFinalizedSelectionGui(false)
	
	RoadBuilderState.SetMovingSelection(false, false)
	
	states.isPromptedSelection(false)
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
		or not capturedStates.isValidRoad -- TODO: probably should still show the selection gui, just dont have the checkmark lol
	then
		return
	end

	-- RoadBuilderEvents.RequestRoadData:InvokeServer(capturedStates.currentGoalPoint.goalPoint.Position)

	--[[
		`isRemaking` is merely a debounce for repositioning/remaking actions

		`wasRemaked` keeps track of any kind of positional change after the first "selection onpress", 
		implies a remake
	]]
	local remakeState = {
		isRemaking = false:: boolean;
		remakeType = nil:: RemakeTypeEnum.RemakeTypeEnum?;

		wasEverRemaked = false:: boolean;
	}

	onPressDebounce = true

	-- just toggle this to remove any error/invalid alerts
	states.isValidRoad(true)
	-- enable selection state, pauses resimulation of clientside roads (sent to the server)
	states.isPromptedSelection(true)

	resetRenderThrottle()
	RoadBuilderState.ResetStates("IsMovingSelection")

	-- prepare remakecache incase of "remake movement"
	clearRemakeRoadsCache()
	cacheRemakeRoads(capturedStates)

	--[[
		make the final road visualization (if applicable)
		just to fix up anything that may have been missed from the renderstep
	]]
	if capturedStates.currentSelectionPoint.selectionPoint then
		RoadBuilderVisualization.ClearVisualizedRoads(
			{capturedStates.currentGoalPoint.goalPoint}
		)
		RoadBuilderState.IsValidRoad(visualizeStandardRoad(capturedStates))
	end

	-- selection prompt gui
	toggleFinalizedSelectionGui(true)
	attachSelectionGui(capturedStates.currentGoalPoint.goalPoint)

	--[[
		MOVEMENT SIGNALS
	]]

	local previousVerticalRay = MouseUtils.GetMouseRay()

	-- vertical remake
	onPressJanitor:Add(SELECTION_GUI_SIGNALS.verticalDragContinue:Connect(function()
		if remakeState.isRemaking and remakeState.remakeType ~= RemakeTypeEnum.Vertical then
			return
		end

		--TODO: ENSURE THIS FUNCTION IS USED ALLTHROUGHOUT
		refreshCapturedStates(capturedStates)

		local verticalDist = (camera.CFrame.Position - capturedStates.currentGoalPoint.goalPoint.Position).Magnitude
		local currentVerticalRay = MouseUtils.GetMouseRay()
		local verticalDelta = ((currentVerticalRay.Direction.Unit * verticalDist).Y - (previousVerticalRay.Direction.Unit * verticalDist).Y)
		--TODO: fit this functionality into the move goal function
		states.currentGoalPoint().goalPoint.Position += Vector3.new(0, verticalDelta, 0)

		previousVerticalRay = currentVerticalRay
	end))
	onPressJanitor:Add(SELECTION_GUI_SIGNALS.verticalDragStarted:Connect(function()
		if remakeState.isRemaking then
			return
		end
		updateRemakingStatus(
			remakeState,
			true,
			RemakeTypeEnum.Vertical
		)

		remakeState.wasEverRemaked = true
		previousVerticalRay = MouseUtils.GetMouseRay()
		toggleRemakeRoadsCache(false)
		RoadBuilderState.SetMovingSelection(true, true)
	end))
	onPressJanitor:Add(SELECTION_GUI_SIGNALS.verticalDragEnded:Connect(function()
		if remakeState.remakeType ~= RemakeTypeEnum.Vertical then
			return
		end
		updateRemakingStatus(
			remakeState,
			false,
			nil
		)

		RoadBuilderState.SetMovingSelection(false, true)
	end))

	--TODO: take away the "reset" term, make it into remake for consistency
	-- freemove remake
	onPressJanitor:Add(SELECTION_GUI_SIGNALS.resetStarted:Connect(function()
		if remakeState.isRemaking then
			return
		end
		updateRemakingStatus(
			remakeState,
			true,
			RemakeTypeEnum.Freemove
		)

		remakeState.wasEverRemaked = true
		toggleRemakeRoadsCache(false)
		RoadBuilderState.SetMovingSelection(true, false)
	end))
	onPressJanitor:Add(SELECTION_GUI_SIGNALS.resetEnded:Connect(function()
		if remakeState.remakeType ~= RemakeTypeEnum.Freemove then
			return
		end
		updateRemakingStatus(
			remakeState,
			false,
			nil
		)

		RoadBuilderState.SetMovingSelection(false, false)
	end))

	--[[
		CONFIRMATION SIGNALS
	]]

	--TODO: so add functions for 1) FireServer() for creating roads and InvokeServer() for getting road cache data

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
			warn("created exn")
			if 
				capturedStates.currentSelectionPoint.selectionPoint.Position 
				~= capturedStates.currentGoalPoint.goalPoint.Position 
			then
				-- warn(`OH NEW ROAD EXTENSION!:`, currentRemakeRoadCache.dependentRoads, `and`, currentRemakeRoadCache.endRoadPoints)
				requestRoadCreation(
					CreateRoadConfig(
						capturedStates.currentRoadType,
						RoadVariantEnums.RoadExtension,
						nil,
						
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
			warn("REMAKE")
			if remakeState.wasEverRemaked then
				--[[
					modify EXISTING ROAD EXTENSION (and override old road extension), 
					interacts with `currentRemakeRoadCache` which is modified by "remake movement"
				]]
				for endRoadPoint, endData in currentRemakeRoadCache.endRoadPoints do
					requestRoadCreation(
						CreateRoadConfig(
							capturedStates.currentRoadType,
							RoadVariantEnums.RoadExtension,
							OverrideRoadConfig(
								true,
								currentRemakeRoadCache.selectionRoadPoint.Position
							),

							PointVector2Data(
								endRoadPoint.Position, 
								endData.direction
							),
							PointVector2Data(capturedStates.currentGoalPoint.goalPoint.Position)
						)
					)
				end

				clearRemakeRoadsCache()
			else
				-- local goalRoadPointCache: RoadPointCache.RoadPointCache = RoadBuilderEvents.RequestRoadData:InvokeServer(capturedStates.currentGoalPoint.goalPoint.Position)
				local goalRoadPointCache: RoadPointCache.RoadPointCache = RoadBuilderCache.GetRoadDataFromVector3(capturedStates.currentGoalPoint.goalPoint.Position)

				--[[
					if road point has existed and has cache, update direction state to cached direction
				]]
				if goalRoadPointCache then
					RoadBuilderState.SetCurrentSelectionDirection(goalRoadPointCache.vector2Direction)

				--[[
					otherwise, NEW ROAD POINT with direction state updated to `DEFAULT_ROAD_POINT_AXIS`
				]]
				else
					requestRoadCreation(
						CreateRoadConfig(
							capturedStates.currentRoadType,
							RoadVariantEnums.RoadPoint,
							nil,

							PointVector2Data(capturedStates.currentGoalPoint.goalPoint.Position)
						)
					)
				end
			end
		end

		toggleRemakeRoadsCache(true)

		-- updated selectedroadpoint
		RoadBuilderState.SetCurrentSelectionPoint(capturedStates.currentGoalPoint.goalPoint)

		-- do not create a new goalpoint if `isRepeatedSelection` is true
		if not isRepeatedSelection then
			local newVisualizedRoadPoint = newRoadPointOnMouse(capturedStates.currentGoalPoint.goalPoint.Position)
			RoadBuilderState.SetCurrentGoalPoint(newVisualizedRoadPoint)
		end

		exitFinalizedSelection(onPressJanitor)
		states.isValidRoad(true)
	end))

	-- when clicking the "undo button"
	onPressJanitor:Add(SELECTION_GUI_SIGNALS.undoTriggered:Once(function()
		refreshCapturedStates(capturedStates)

		-- reset selectedroadpoint
		RoadBuilderState.SetCurrentSelectionPoint(nil)
		RoadBuilderVisualization.AttachFocusHighlight(capturedStates.currentGoalPoint.goalPoint)

		-- -- undo any "remake movement"
		toggleRemakeRoadsCache(true)

		exitFinalizedSelection(onPressJanitor)
		states.isValidRoad(true)
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

			RoadBuilderVisualization.AttachFocusHighlight(mouseRoadPoint)

		-- if player is no longer in build menu, clear selected road data
		else
			Debris:AddItem(capturedStates.currentGoalPoint.goalPoint)

			onPressJanitor:Cleanup()
			RoadBuilderVisualization.ClearVisualizedRoads()
			RoadBuilderState.ResetStates()

			attachSelectionGui(nil)
		end
	end)

	-- error alert
	Vide.effect(function()
		local capturedStates = RoadBuilderState.CaptureStates()

		if states.isValidRoad() then
			warn("CLEARRR!!")
			RoadBuilderErrorAlert.ClearErrorAlerts()
		else
			RoadBuilderErrorAlert.CreateErrorAlert(capturedStates.currentGoalPoint.goalPoint)
		end
	end)
end)

-- whenever a new road is built on the server, this is fired back to the client for road visualization "correction"
--TODO: err maybe remove the boolean here?
RoadBuilderEvents.CreateRoadRequest.OnClientEvent:Connect(function(boolean, direction)
	RoadBuilderState.SetCurrentSelectionDirection(direction)
end)

local function moveCurrentGoalPoint(position: Vector3)
	Vide.untrack(states.currentGoalPoint).goalPoint.Position = position
end

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
			/ RoadVisualizationConfig.RENDER_THROTTLE_PER_ROAD_DISTANCE.roadverticalDistance
		)
end

-- this could be a state machine tbh
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
		or not capturedStates.currentGoalPoint.goalPoint -- weird, should always have a goalpoint at initiation

	-- then, stop rerendering of visualized road
	then
		-- warn(`ispromptedslel: {capturedStates.isPromptedSelection} ismoving: {capturedStates.isMovingSelection.isMoving}`)
		states.isVisualizing(false)
		return

	-- else, continue with rerendering of visualized road
	else
		-- clear current (cached) visualization data, runs destructor functions
		RoadBuilderVisualization.ClearVisualizedRoads(
			{capturedStates.currentGoalPoint.goalPoint}
		)

		currentMouseCast = MouseUtils.GetMouseCast()
		if not currentMouseCast then -- dont create new visualization if no raycastresult from mouse
			return
		end

		local mouseCastPosition = currentMouseCast.Position
		local mouseCastInstance = currentMouseCast.Instance

		--[[
			checks if instance has been actually cached, 
			our way of doublechecking if a roadpoint is merely a visualization or not
		]]
		local isCastInstanceValidSelection = RoadBuilderSelectionValidator.IsValidRoadPoint(mouseCastInstance)

		-- moving existing road point (and, if applicable, override connected roads via visualizeRemakeRoad())
		if 
			capturedStates.isHoveringExistingRoadPoint
			and capturedStates.isMovingSelection.isMoving
			and not capturedStates.currentSelectionPoint.selectionPoint
		then
			RoadBuilderState.IsValidRoad(visualizeRemakeRoad(capturedStates))

			-- normal move-to-cursor, examples of `isCustomPosition` is vertical movement
			if not capturedStates.isMovingSelection.isCustomPosition then
				moveCurrentGoalPoint(mouseCastPosition)
			end

		-- moving visualized road point (and, if applicable, create connected roads via visualizeStandardRoad())
		else
			local isSelectingExistingRoad = (
				isCastInstanceValidSelection
				and mouseCastInstance ~= capturedStates.currentSelectionPoint.selectionPoint
			)
			local goalPosition = isSelectingExistingRoad
				and mouseCastInstance.Position
				or mouseCastPosition

			local isEndPoint = mouseCastInstance:HasTag(RoadPointCacheTypeEnums.EndPoint)

			if capturedStates.currentSelectionPoint.selectionPoint then
				RoadBuilderState.IsValidRoad(visualizeStandardRoad(capturedStates))
			end

			states.isHoveringExistingRoadPoint(isSelectingExistingRoad)
			if not capturedStates.isMovingSelection.isCustomPosition then
				moveCurrentGoalPoint(goalPosition)
			end

			RoadBuilderVisualization.SetFocusHighlightColor(
				isEndPoint
					and FocusHighlightEnum.EndPointHighlight
					or FocusHighlightEnum.DependentPointHighlight
			)

			-- either existing instance or nil
			RoadBuilderState.SetCurrentGoalReference(isSelectingExistingRoad and mouseCastInstance)
		end

		handleRenderThrottling(capturedStates)

		states.isVisualizing(true)
	end
end)

--TODO: OK VISUALIZE ALL ROAD POINTS WHILE IN SELECTION MODE
