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
local remakeRoadCache= {
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
		if states.isHoveringExistingRoadPoint() then
			for endRoadPoint, endData in remakeRoadCache.endRoadPoints do
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
			--[[
				road extension creation with the newly updated direction state from roadpoint selection
				after each request, the direction state is again reupdated via `CreateRoadRequest.OnClientEvent`
			]]
			if states.currentSelectionPoint().selectionPoint then
				RoadBuilderEvents.CreateRoadRequest:FireServer(
					states.currentRoadType(),
					RoadVariantEnums.RoadExtension,
					PointVector2Data(
						states.currentSelectionPoint().selectionPoint.Position, 
						states.currentSelectionPoint().selectionDirection
					),
					PointVector2Data(states.currentGoalPoint().goalPoint.Position)
				)

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
		end

		-- updated selectedroadpoint
		RoadBuilderState.SetCurrentSelectionPoint(states.currentGoalPoint().goalPoint)

		local newSimulatedRoadPoint = newRoadPointOnMouse(states.currentGoalPoint().goalPoint.Position)
		RoadBuilderState.SetCurrentGoalPoint(newSimulatedRoadPoint)

		exitFinalizedSelection(onPressJanitor)
		
		for _, remakeTable: {[any]: any} in remakeRoadCache do
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
		for _, dependentRoad in remakeRoadCache.dependentRoads do
			dependentRoad.Transparency = 0
		end
		
		for _, remakeTable: {[any]: any} in remakeRoadCache do
			table.clear(remakeTable)
		end
	end))

	-- "reset movement button"
	onPressJanitor:Add(SELECTION_GUI_SIGNALS.resetStarted:Connect(function()
		local isMoving = not states.isMovingSelection().isMoving

		RoadBuilderState.SetMovingSelection(isMoving, false)
	end))
end)

--TODO: SURELY WE DONT HAVE TO KEEP THIS
RoadBuilderState.ScopeState(function()
	-- build menu state
	Vide.effect(function()
		local capturedStates = RoadBuilderState.CaptureStates()

		if states.isInBuildMenu() then
			-- create the endroadpoint ONCE throughout the entire
			local mouseRoadPoint = newRoadPointOnMouse()
			if mouseRoadPoint then
				RoadBuilderState.SetCurrentGoalPoint(mouseRoadPoint)
			end

			onPressDebounce = false
			toggleFinalizedSelectionGui(false)
			attachSelectionGui(mouseRoadPoint)
			RoadBuilderRoadSimulation.AttachFocusHighlight(mouseRoadPoint)

		--[[
			if state is exited (meaning player is no longer in build menu)
			clear selected road data
		]]
		else
			Debris:AddItem(capturedStates.currentGoalPoint.goalPoint)

			onPressJanitor:Cleanup()
			RoadBuilderRoadSimulation.ClearVisualizedRoads()
			RoadBuilderState.ResetStates()

			attachSelectionGui(nil)
		end
	end)

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

			local dependentRoads = goalPointCache.dependentRoads

			table.move(
				dependentRoads,
				1,
				#dependentRoads,
				#remakeRoadCache.dependentRoads + 1,
				remakeRoadCache.dependentRoads
			)
			table.insert(remakeRoadCache.dependentRoads, capturedStates.currentGoalPoint.referenceInstance)

			for _, endRoadPoint in goalPointCache.pairExtensionEndRoadPoints do
				local endRoadPointCache: RoadPointCache.RoadPointCache = RoadBuilderEvents.RequestRoadData:InvokeServer(endRoadPoint.Position)
				remakeRoadCache.endRoadPoints[endRoadPoint] = {
					direction = endRoadPointCache.vector2Direction;
				}
			end

			for _, dependentRoad in remakeRoadCache.dependentRoads do
				dependentRoad.Transparency = 1
			end
		end
	end)

	-- handling `isHoveringExistingRoadPoint()` state
	Vide.effect(function()
		local capturedStates = RoadBuilderState.CaptureStates()

		if states.isHoveringExistingRoadPoint() then
			if not capturedStates.isVisualizing then
				return
			end	
	
			toggleGoalPointVisibility(false)
		else
			if not capturedStates.isVisualizing then
				return
			end	

			toggleGoalPointVisibility(true)
		end
	end)
end)

-- whenever a new road is built on the server, this is fired back to the client for road visualization "correction"
RoadBuilderEvents.CreateRoadRequest.OnClientEvent:Connect(function(boolean, direction)
	RoadBuilderState.SetCurrentSelectionDirection(direction)
end)

RunService.Heartbeat:Connect(function()
	-- render throttling the visualization code itself (depending on how far the road is from the player)
	if renderThrottle > 0 then
		renderThrottle -= task.wait()
		return
	end

	local capturedStates = RoadBuilderState.CaptureStates()

	-- has selected? prevent clearing of visualized road
	if 
		not capturedStates.isInBuildMenu
		or (capturedStates.isPromptedSelection and not capturedStates.isMovingSelection.isMoving)
	then
		warn(`ispromptedslel: {capturedStates.isPromptedSelection} ismoving: {capturedStates.isMovingSelection.isMoving}`)
		states.isVisualizing(false)
		return

	-- else, continue with visualization rerender
	else
		-- clear current (cached) visualization data
		RoadBuilderRoadSimulation.ClearVisualizedRoads(
			{capturedStates.currentGoalPoint.goalPoint}
		)

		-- dont create new visualization if no raycastresult from mouse
		currentMouseCast = MouseUtils.GetMouseCast()
		if not currentMouseCast then
			return
		end
		
		local mouseCastPosition = currentMouseCast.Position
		local isCastInstanceValidSelection = RoadBuilderSelectionValidator.VerifyRoadPoint(currentMouseCast.Instance)

		if 
			capturedStates.isMovingSelection.isMoving 
			and capturedStates.isHoveringExistingRoadPoint
		then
			for endRoadPoint, endData in remakeRoadCache.endRoadPoints do
				RoadBuilderRoadSimulation.SimulateRoadExtension(
					capturedStates.currentRoadType,
					PointVector2Data(
						endRoadPoint.Position, 
						endData.direction
					),
					PointVector2Data(states.currentGoalPoint().goalPoint.Position)
				)
			end

			if not states.isMovingSelection().isCustomPosition then
				states.currentGoalPoint().goalPoint.Position = mouseCastPosition
			end

		else
			-- moving existing road points
			if 
				isCastInstanceValidSelection
				and currentMouseCast.Instance ~= capturedStates.currentSelectionPoint.selectionPoint
			then
				states.isHoveringExistingRoadPoint(true)

				if not states.isMovingSelection().isCustomPosition then
					states.currentGoalPoint().goalPoint.Position = currentMouseCast.Instance.Position
				end
				RoadBuilderState.SetCurrentGoalReference(currentMouseCast.Instance)

			-- moving/creating new road points
			else
				states.isHoveringExistingRoadPoint(false)

				if capturedStates.currentSelectionPoint.selectionPoint then
					local selectedRoadToMouseDistance = (
						capturedStates.currentSelectionPoint.selectionPoint.Position 
						- states.currentGoalPoint().goalPoint.Position
					).Magnitude
					renderThrottle = selectedRoadToMouseDistance * (RENDER_THROTTLE_PER_ROAD_DISTANCE.throttleSeconds / RENDER_THROTTLE_PER_ROAD_DISTANCE.roadverticalDistance)
		
					RoadBuilderRoadSimulation.SimulateRoadExtension(
						capturedStates.currentRoadType,
						PointVector2Data(
							capturedStates.currentSelectionPoint.selectionPoint.Position, 
							capturedStates.currentSelectionPoint.selectionDirection
						),
						PointVector2Data(states.currentGoalPoint().goalPoint.Position)
					)
					warn("move this!!!")
				end

				if not states.isMovingSelection().isCustomPosition then
					states.currentGoalPoint().goalPoint.Position = mouseCastPosition
				end
				
				RoadBuilderState.SetCurrentGoalReference(nil)
			end
		end

		states.isVisualizing(true)
	end
end)
