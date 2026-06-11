local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")
local Stats = game:GetService("Stats")

local RoadBuilderCreation = require(ReplicatedStorage.RoadBuilder.RoadBuilderCreation)
local RoadPointCache = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.CacheDataWrappers.RoadPointCache)
local PointVector2Data = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.PointVector2Data)
local RoadVariantEnums = require(ReplicatedStorage.RoadBuilder.RoadBuilderEnums.RoadVariantEnums)
local MouseUtils = require(StarterPlayer.StarterPlayerScripts.ClientUtils.MouseUtils)
local RoadBuilderEvents = require(ReplicatedStorage.RoadBuilder.RoadBuilderEvents)
local RoadBuilderSelectionValidator = require(ReplicatedStorage.RoadBuilder.RoadBuilderUtils.RoadBuilderSelectionValidator)
local Janitor = require(ReplicatedStorage.SharedPackages.Janitor)
local Vide = require(ReplicatedStorage.SharedPackages.Vide)
local InputManager = require(StarterPlayer.StarterPlayerScripts.Inputs.InputManager)
local RoadBuilderState = require(StarterPlayer.StarterPlayerScripts.RoadBuilderClient.RoadBuilderState)
local RoadBuilderRoadSimulation = require(StarterPlayer.StarterPlayerScripts.RoadBuilderClient.RoadBuilderUtils.RoadBuilderRoadSimulation)
local RoadBuilderSelectionPrompt = require(StarterPlayer.StarterPlayerScripts.RoadBuilderClient.RoadBuilderUtils.RoadBuilderSelectionPrompt)

--// CONFIGURATION

local RENDER_THROTTLE_PER_ROAD_DISTANCE = {
	throttleSeconds = .05;
	roadverticalDistance = 600;
}
local BUILD_YIELD_BEFORE_RESIMULATION_RESET = .25
local SELECTION_GUI, SELECTION_GUI_SIGNALS, SELECTION_GUI_DESTRUCTOR = RoadBuilderSelectionPrompt.CreateSelectionPrompt()

local camera = workspace.CurrentCamera
local states = RoadBuilderState.GetStates()


--[[
	ONPRESS INPUT (placing a road)
]]

local onPressJanitor = Janitor.new()
local onPressDebounce = false

--[[
	ROAD VISUALIZATION
]]

local currentMouseCast: RaycastResult
local renderThrottle = 0
local currentRemakeRoadCache= {
	dependentRoads = {}:: {BasePart?};
	endRoadPoints = {}:: {
		[BasePart]: {
			direction: Vector2
		};
	};
}

local function newRoadPointOnMouse(positionBackup: Vector3?): (BasePart, () -> ())
	local mouseCast = MouseUtils.GetMouseCast()

	local mousePosition = mouseCast and mouseCast.Position or positionBackup
	local mouseRoadPoint, mouseRoadPointDestructor = RoadBuilderRoadSimulation.SimulateRoadPoint(
		RoadBuilderState.CurrentRoadType(),
		PointVector2Data(mousePosition)
	)

	return mouseRoadPoint, mouseRoadPointDestructor
end

local function toggleFinalizedSelectionGui(isFinalizing: boolean)
	SELECTION_GUI.gui.Enabled = isFinalizing
end

local function attachSelectionGui(adornee: Instance)
	SELECTION_GUI.gui.Adornee = adornee
	if not adornee then
		SELECTION_GUI.gui.Enabled = false
	end
end

local function toggleGoalPointVisibility(isVisible: boolean)
	local goalPoint = Vide.untrack(states.currentGoalPoint).goalPoint

	-- can be nil, mostly because of how Vide effects work
	if goalPoint then
		goalPoint.Transparency = isVisible and 0 or 1
	end
end

local function exitFinalizedSelection(janitor: Janitor.Janitor)
	janitor:Cleanup()
	toggleFinalizedSelectionGui(false)
	onPressDebounce = false
	
	RoadBuilderState.SetMovingSelection(false, false)
	states.isPromptedSelection(false)
end

local function isMovingExistingRoad()
	return 
		states.isHoveringExistingRoadPoint()
		and states.isMovingSelection().isMoving
		and #currentRemakeRoadCache.dependentRoads > 0
end

--[[
	acknowledges selection clicks

	when a click is valid, creates a selection gui and its respective signals
	which will be kept until the X button is pressed, destroying the gui and its signals

	and thereby toggling `onPressDebounce` to allow for another selection click
]]
InputManager.OnPress:Connect(function()
	if 
		onPressDebounce
		or not states.isInBuildMenu()
		or not states.currentGoalPoint().goalPoint
	then
		return
	end

	renderThrottle = 0
	RoadBuilderState.ResetStates("IsMovingSelection")
	onPressDebounce = true

	-- enable selection state, pauses resimulation of clientside roads (sent to the server)
	states.isPromptedSelection(true)

	-- selection prompt gui
	toggleFinalizedSelectionGui(true)
	attachSelectionGui(states.currentGoalPoint().goalPoint)

	--[[
		MOVEMENT SIGNALS
	]]

	local verticalDist = (camera.CFrame.Position - states.currentGoalPoint().goalPoint.Position).Magnitude
	local previousVerticalRay = MouseUtils.GetMouseRay()
	local verticalDelta = 0

	onPressJanitor:Add(SELECTION_GUI_SIGNALS.verticalDragContinue:Connect(function()
		verticalDist = (camera.CFrame.Position - states.currentGoalPoint().goalPoint.Position).Magnitude

		local currentVerticalRay = MouseUtils.GetMouseRay()

		verticalDelta = ((currentVerticalRay.Direction.Unit * verticalDist).Y - (previousVerticalRay.Direction.Unit * verticalDist).Y)
		states.currentGoalPoint().goalPoint.Position += Vector3.new(0, verticalDelta, 0)

		previousVerticalRay = currentVerticalRay
	end))
	onPressJanitor:Add(SELECTION_GUI_SIGNALS.verticalDragStarted:Connect(function()
		previousVerticalRay = MouseUtils.GetMouseRay()
		RoadBuilderState.SetMovingSelection(true, true)
	end))
	onPressJanitor:Add(SELECTION_GUI_SIGNALS.verticalDragEnded:Connect(function()
		RoadBuilderState.SetMovingSelection(false, true)
	end))

	--[[
		CONFIRMATION SIGNALS
	]]

	-- when clicking the "select button"
	onPressJanitor:Add(SELECTION_GUI_SIGNALS.selectTriggered:Once(function()
		--[[
			road extension creation with the newly updated direction state from roadpoint selection
			after each request, the direction state is again reupdated via `CreateRoadRequest.OnClientEvent`
		]]
		if states.currentSelectionPoint().selectionPoint then
			--[[
				the state of this is frozen by the time the player enters the selection gui
				so there isnt any worry of unforeseen state changes
			]]
			if states.isHoveringExistingRoadPoint() then
				for endRoadPoint, endData in currentRemakeRoadCache.endRoadPoints do
					RoadBuilderEvents.CreateRoadRequest:FireServer(
						states.currentRoadType(),
						RoadVariantEnums.RoadExtension,
						PointVector2Data(
							endRoadPoint.Position, 
							endData.direction
						),
						PointVector2Data(states.currentGoalPoint().goalPoint.Position)
					)
				end
			else
				RoadBuilderEvents.CreateRoadRequest:FireServer(
					states.currentRoadType(),
					RoadVariantEnums.RoadExtension,
					PointVector2Data(
						states.currentSelectionPoint().selectionPoint.Position, 
						states.currentSelectionPoint().selectionDirection
					),
					PointVector2Data(states.currentGoalPoint().goalPoint.Position)
				)
			end

		-- road point selection/creation, reupdates the direction state
		else
			local goalRoadPointCache: RoadPointCache.RoadPointCache = RoadBuilderEvents.RequestRoadData:InvokeServer(states.currentGoalPoint().goalPoint.Position)

			-- if road point has existed and has cache, update direction state to cached direction
			if goalRoadPointCache then
				RoadBuilderState.SetCurrentSelectionDirection(goalRoadPointCache.vector2Direction)

			-- otherwise, create completely new roadpoint and update direction state to `DEFAULT_ROAD_POINT_AXIS`
			else
				RoadBuilderEvents.CreateRoadRequest:FireServer(
					states.currentRoadType(),
					RoadVariantEnums.RoadPoint,
					PointVector2Data(states.currentGoalPoint().goalPoint.Position)
				)
				RoadBuilderState.SetCurrentSelectionDirection(RoadBuilderCreation.DEFAULT_ROAD_POINT_AXIS)
			end
		end

		-- updated selectedroadpoint
		RoadBuilderState.SetCurrentSelectionPoint(states.currentGoalPoint().goalPoint)

		local newSimulatedRoadPoint = newRoadPointOnMouse(states.currentGoalPoint().goalPoint.Position)
		RoadBuilderState.SetCurrentGoalPoint(newSimulatedRoadPoint)

		exitFinalizedSelection(onPressJanitor)
		
		for _, remakeTable: {[any]: any} in currentRemakeRoadCache do
			table.clear(remakeTable)
		end
	end))

	-- when clicking the "undo button"
	onPressJanitor:Add(SELECTION_GUI_SIGNALS.undoTriggered:Once(function()
		-- reset selectedroadpoint
		RoadBuilderState.SetCurrentSelectionPoint(nil)

		exitFinalizedSelection(onPressJanitor)
		RoadBuilderRoadSimulation.AttachFocusHighlight(states.currentGoalPoint().goalPoint)

		--TODO: prolly have a function for these below
		for _, dependentRoad in currentRemakeRoadCache.dependentRoads do
			dependentRoad.Transparency = 0
		end
		
		for _, remakeTable: {[any]: any} in currentRemakeRoadCache do
			table.clear(remakeTable)
		end
	end))

	-- "reset movement button"
	onPressJanitor:Add(SELECTION_GUI_SIGNALS.resetStarted:Connect(function()
		local isMoving = not states.isMovingSelection().isMoving

		RoadBuilderState.SetMovingSelection(isMoving, false)
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

			RoadBuilderRoadSimulation.AttachFocusHighlight(mouseRoadPoint)

		-- if player is no longer in build menu, clear selected road data
		else
			Debris:AddItem(capturedStates.currentGoalPoint.goalPoint)

			onPressJanitor:Cleanup()
			RoadBuilderRoadSimulation.ClearVisualizedRoads()
			RoadBuilderState.ResetStates()

			attachSelectionGui(nil)
		end
	end)

	--[[
		TODO: CONSIDER MAKING IT SO THAT THIS CACHE IS INSTEAD HANDLED ON SELECTION PROMPT INIT
		CUZ THE BEHAVIOR OF THIS IS LOWKEY AMBIGIOUS, thanks
	]]
	-- necessary data updates for visualizeRemakeRoad() system
	Vide.effect(function()
		local capturedStates = RoadBuilderState.CaptureStates()

		if 
			states.isMovingSelection().isMoving 
			and capturedStates.isHoveringExistingRoadPoint
		then
			local goalPointCache: RoadPointCache.RoadPointCache = RoadBuilderEvents.RequestRoadData:InvokeServer(capturedStates.currentGoalPoint.goalPoint.Position)
			if not goalPointCache then
				return
			end

			local dependentRoads: {BasePart?} = goalPointCache.dependentRoads
			table.clear(currentRemakeRoadCache.dependentRoads)
			table.clear(currentRemakeRoadCache.endRoadPoints)

			table.move(
				dependentRoads,
				1,
				#dependentRoads,
				#currentRemakeRoadCache.dependentRoads + 1,
				currentRemakeRoadCache.dependentRoads
			)
			table.insert(currentRemakeRoadCache.dependentRoads, capturedStates.currentGoalPoint.referenceInstance)

			for _, endRoadPoint in goalPointCache.pairExtensionEndRoadPoints do
				local endRoadPointCache: RoadPointCache.RoadPointCache = RoadBuilderEvents.RequestRoadData:InvokeServer(endRoadPoint.Position)
				currentRemakeRoadCache.endRoadPoints[endRoadPoint] = {
					direction = endRoadPointCache.vector2Direction;
				}
			end

			for _, dependentRoad in currentRemakeRoadCache.dependentRoads do
				dependentRoad.Transparency = 1
			end
		end
	end)
end)

local function visualizeRemakeRoad(capturedStates: RoadBuilderState.CapturedStates)
	for endRoadPoint, endData in currentRemakeRoadCache.endRoadPoints do
		RoadBuilderRoadSimulation.SimulateRoadExtension(
			capturedStates.currentRoadType,
			PointVector2Data(
				endRoadPoint.Position, 
				endData.direction
			),
			PointVector2Data(states.currentGoalPoint().goalPoint.Position)
		)
	end
end

local function visualizeStandardRoad(capturedStates: RoadBuilderState.CapturedStates)
	RoadBuilderRoadSimulation.SimulateRoadExtension(
		capturedStates.currentRoadType,
		PointVector2Data(
			capturedStates.currentSelectionPoint.selectionPoint.Position, 
			capturedStates.currentSelectionPoint.selectionDirection
		),
		PointVector2Data(states.currentGoalPoint().goalPoint.Position)
	)
end

local function moveCurrentGoalPoint(position: Vector3)
	states.currentGoalPoint().goalPoint.Position = position
end

-- whenever a new road is built on the server, this is fired back to the client for road visualization "correction"
RoadBuilderEvents.CreateRoadRequest.OnClientEvent:Connect(function(boolean, direction)
	RoadBuilderState.SetCurrentSelectionDirection(direction)
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
	renderThrottle = selectedRoadToMouseDistance * (RENDER_THROTTLE_PER_ROAD_DISTANCE.throttleSeconds / RENDER_THROTTLE_PER_ROAD_DISTANCE.roadverticalDistance)
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
	
	-- then, stop rerendering of visualized road
	then
		warn(`ispromptedslel: {capturedStates.isPromptedSelection} ismoving: {capturedStates.isMovingSelection.isMoving}`)
		states.isVisualizing(false)
		return

	-- else, continue with rerendering of visualized road
	else
		-- clear current (cached) visualization data
		RoadBuilderRoadSimulation.ClearVisualizedRoads(
			{capturedStates.currentGoalPoint.goalPoint}
		)

		currentMouseCast = MouseUtils.GetMouseCast()
		if not currentMouseCast then -- dont create new visualization if no raycastresult from mouse
			return
		end

		local mouseCastPosition = currentMouseCast.Position
		local isCastInstanceValidSelection = RoadBuilderSelectionValidator.VerifyRoadPoint(currentMouseCast.Instance)

		--[[
			TODO: unsure about the (#currentRemakeRoadCache.dependentRoads > 0) line, 
			would be more verbose to have a boolean alongside currentRemakeRoadCache

			kinda like currentRemakeRoadCache.isRemaking
		]]

		-- moving existing road points (if applicable, move connected roads via visualizeRemakeRoad())
		if 
			capturedStates.isMovingSelection.isMoving 
			and #currentRemakeRoadCache.dependentRoads > 0
			and capturedStates.isHoveringExistingRoadPoint
			and capturedStates.currentGoalPoint ~= currentMouseCast.Instance
		then
			visualizeRemakeRoad(capturedStates)

			-- normal move-to-cursor, examples of `isCustomPosition` is vertical movement
			if not states.isMovingSelection().isCustomPosition then
				moveCurrentGoalPoint(mouseCastPosition)
			end

		-- creating new roads / road points
		else
			-- moving existing road points
			local isSelectingExistingRoad = (
				isCastInstanceValidSelection
				and currentMouseCast.Instance ~= capturedStates.currentSelectionPoint.selectionPoint
			)
			local goalPosition = isSelectingExistingRoad
				and currentMouseCast.Instance.Position
				or mouseCastPosition

			if capturedStates.currentSelectionPoint.selectionPoint then
				visualizeStandardRoad(capturedStates)
			end

			states.isHoveringExistingRoadPoint(isSelectingExistingRoad)
			moveCurrentGoalPoint(goalPosition)
			RoadBuilderState.SetCurrentGoalReference(isSelectingExistingRoad and currentMouseCast.Instance)
		end

		handleRenderThrottling(capturedStates)

		states.isVisualizing(true)
	end
end)
