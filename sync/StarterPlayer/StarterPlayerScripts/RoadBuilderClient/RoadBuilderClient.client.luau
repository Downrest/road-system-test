local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")

local RoadBuilderCreation = require(ReplicatedStorage.RoadBuilder.RoadBuilderCreation)
local RoadPointCache = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.CacheDataWrappers.RoadPointCache)
local PointVector2Data = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.PointVector2Data)
local RoadVariantEnums = require(ReplicatedStorage.RoadBuilder.RoadBuilderEnums.RoadVariantEnums)
local MouseUtils = require(StarterPlayer.StarterPlayerScripts.ClientUtils.MouseUtils)
local RoadBuilderEvents = require(ReplicatedStorage.RoadBuilder.RoadBuilderEvents)
local RoadBuilderSelectionValidator = require(ReplicatedStorage.RoadBuilder.RoadBuilderUtils.RoadBuilderSelectionValidator)
local Janitor = require(ReplicatedStorage.SharedPackages.Janitor)
local InputManager = require(StarterPlayer.StarterPlayerScripts.Inputs.InputManager)
local RoadBuilderState = require(StarterPlayer.StarterPlayerScripts.RoadBuilderClient.RoadBuilderState)
local RoadBuilderVisualizer = require(StarterPlayer.StarterPlayerScripts.RoadBuilderClient.RoadBuilderUtils.RoadBuilderVisualizer)

--// CONFIGURATION

local STUDS_PER_VERTICAL_MOVEMENT_PIXELS = {
	studs = 5;
	pixels = 500;
}
local RENDER_THROTTLE_PER_ROAD_verticalDistANCE = {
	throttleSeconds = .05;
	roadverticalDistance = 600;
}
local BUILD_YIELD_BEFORE_RESIMULATION_RESET = .25

local camera = workspace.CurrentCamera
local states = RoadBuilderState.GetStates()
local renderThrottle = 0

local currentMouseCast: RaycastResult

--[[
	client merely sends requests to the server
	to prompt road creation
]]
InputManager.OnPress:Connect(function()
	local capturedStates = RoadBuilderState.CaptureStates()

	if 
		not capturedStates.isInBuildMenu
		or not capturedStates.simulatedRoadPoint
	then
		return
	end

	renderThrottle = 0

	-- enable selection state, pauses resimulation of clientside roads (sent to the server)
	states.isPromptedSelection(true)

	-- selection prompt gui (while clearing the previous prompt guis)
	RoadBuilderVisualizer.ClearVisualizationData(RoadBuilderVisualizer.selectionDataContainer)
	local _, visualizerSignals, visualizerDestructor = RoadBuilderVisualizer.AddSelectionPrompt(capturedStates.simulatedRoadPoint)

	local onPressJanitor = Janitor.new()

	local function onPressDestructor()
		onPressJanitor:Destroy()
		visualizerDestructor()
	end

	--[[
		MOVEMENT SIGNALS
	]]

	local verticalDist = (camera.CFrame.Position - capturedStates.simulatedRoadPoint.Position).Magnitude
	local previousVerticalRay = MouseUtils.GetMouseRay()
	local verticalDelta = 0

	onPressJanitor:Add(visualizerSignals.verticalDragContinue:Connect(function()
		verticalDist = (camera.CFrame.Position - capturedStates.simulatedRoadPoint.Position).Magnitude

		local currentVerticalRay = MouseUtils.GetMouseRay()

		verticalDelta = ((currentVerticalRay.Direction.Unit * verticalDist).Y - (previousVerticalRay.Direction.Unit * verticalDist).Y)
		capturedStates.simulatedRoadPoint.Position += Vector3.new(0, verticalDelta, 0)

		previousVerticalRay = currentVerticalRay
	end))
	onPressJanitor:Add(visualizerSignals.verticalDragStarted:Connect(function()
		previousVerticalRay = MouseUtils.GetMouseRay()
	end))

	--[[
		CONFIRMATION SIGNALS
	]]

	-- when clicking the "select button"
	onPressJanitor:Add(visualizerSignals.selectTriggered:Once(function()
		--[[
			road extension creation with the newly updated direction state from roadpoint selection
			after each request, the direction state is again reupdated via `CreateRoadRequest.OnClientEvent`
		]]
		if states.selectedRoadPoint() then
			RoadBuilderEvents.CreateRoadRequest:FireServer(
				capturedStates.currentRoadType,
				RoadVariantEnums.RoadExtension,
				PointVector2Data(capturedStates.selectedRoadPoint.Position, states.selectedRoadVector2Direction()),
				PointVector2Data(capturedStates.simulatedRoadPoint.Position)
			)

		-- road point selection/creation, reupdates the direction state
		else
			local simulatedRoadPointCache: RoadPointCache.RoadPointCache = RoadBuilderEvents.RequestRoadData:InvokeServer(capturedStates.simulatedRoadPoint.Position)

			-- if road point has existed and has cache, update direction state to cached direction
			if simulatedRoadPointCache then
				states.selectedRoadVector2Direction(simulatedRoadPointCache.vector2Direction)

			-- otherwise, create completely new roadpoint and update direction state to `DEFAULT_ROAD_POINT_AXIS`
			else
				RoadBuilderEvents.CreateRoadRequest:FireServer(
					capturedStates.currentRoadType,
					RoadVariantEnums.RoadPoint,
					PointVector2Data(capturedStates.simulatedRoadPoint.Position)
				)
				states.selectedRoadVector2Direction(RoadBuilderCreation.DEFAULT_ROAD_POINT_AXIS)
			end
		end

		-- updated selectedroadpoint
		states.selectedRoadPoint(capturedStates.simulatedRoadPoint)
		onPressDestructor()
		states.isPromptedSelection(false)
	end))

	-- when clicking the "undo button"
	onPressJanitor:Add(visualizerSignals.undoTriggered:Once(function()
		-- reset selectedroadpoint
		states.selectedRoadPoint(nil)
		onPressDestructor()
		states.isPromptedSelection(false)
	end))
end)

RoadBuilderState.ScopeState(function(effect)
	effect(function()
		--[[
			if state is exited (meaning player is no longer in build menu)
			clear selected road data
		]]
		if not states.isInBuildMenu() then
			RoadBuilderVisualizer.ClearVisualizationData(RoadBuilderVisualizer.simulatedRoadContainer)
			RoadBuilderVisualizer.ClearVisualizationData(RoadBuilderVisualizer.selectionDataContainer)
			RoadBuilderState.ResetStates()
		end
	end)
end)

-- whenever a new road is built on the server, this is fired back to the client for road visualization "correction"
RoadBuilderEvents.CreateRoadRequest.OnClientEvent:Connect(function(boolean, direction)
	states.selectedRoadVector2Direction(direction)
end)

RunService.RenderStepped:Connect(function()
	if renderThrottle > 0 then
		renderThrottle -= task.wait()
		return
	end

	local capturedStates = RoadBuilderState.CaptureStates()

	-- has selected? prevent clearing of visualized road
	if 
		not capturedStates.isInBuildMenu
		or capturedStates.isPromptedSelection
	then
		return

	-- else, continue with visualization rerender
	else
		-- clear current visualization data
		RoadBuilderVisualizer.ClearVisualizationData(RoadBuilderVisualizer.simulatedRoadContainer)

		-- dont create new visualization if no raycastresult from mouse
		currentMouseCast = MouseUtils.GetMouseCast()
		if not currentMouseCast then
			return
		end
		
		local castPosition = currentMouseCast.Position
		local isCastInstanceValidSelection = RoadBuilderSelectionValidator.VerifyRoadPoint(currentMouseCast.Instance)

		local simulatedInstance: BasePart

		if capturedStates.selectedRoadPoint then
			local selectedRoadToMouseverticalDistance = (capturedStates.selectedRoadPoint.Position - castPosition).Magnitude
			renderThrottle = selectedRoadToMouseverticalDistance * (RENDER_THROTTLE_PER_ROAD_verticalDistANCE.throttleSeconds / RENDER_THROTTLE_PER_ROAD_verticalDistANCE.roadverticalDistance)

			simulatedInstance = RoadBuilderVisualizer.SimulateRoadExtension(
				capturedStates.currentRoadType,
				PointVector2Data(
					capturedStates.selectedRoadPoint.Position, 
					states.selectedRoadVector2Direction()
				),
				PointVector2Data(
					isCastInstanceValidSelection 
						and currentMouseCast.Instance.Position
						or castPosition
				)
			)
		else
			if isCastInstanceValidSelection then
				simulatedInstance = currentMouseCast.Instance
			else
				simulatedInstance = RoadBuilderVisualizer.SimulateRoadPoint(
					capturedStates.currentRoadType,
					PointVector2Data(castPosition)
				)
			end

			RoadBuilderVisualizer.AttachRoadPointHighlight(simulatedInstance)
		end

		states.simulatedRoadPoint(simulatedInstance)
	end
end)
