local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")

local RoadPointCache = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.CacheDataWrappers.RoadPointCache)
local PointVector2Data = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.PointVector2Data)
local RoadVariantEnums = require(ReplicatedStorage.RoadBuilder.RoadBuilderEnums.RoadVariantEnums)
local MouseUtils = require(StarterPlayer.StarterPlayerScripts.ClientUtils.MouseUtils)
local RoadBuilderEvents = require(ReplicatedStorage.RoadBuilder.RoadBuilderEvents)
local RoadBuilderSelectionValidator = require(ReplicatedStorage.RoadBuilder.RoadBuilderUtils.RoadBuilderSelectionValidator)
local InputManager = require(StarterPlayer.StarterPlayerScripts.Inputs.InputManager)
local RoadBuilderState = require(StarterPlayer.StarterPlayerScripts.RoadBuilderClient.RoadBuilderState)
local RoadBuilderVisualizer = require(StarterPlayer.StarterPlayerScripts.RoadBuilderClient.RoadBuilderUtils.RoadBuilderVisualizer)

--// CONFIGURATION

local DEFAULT_ROAD_POINT_AXIS = Vector2.xAxis
local RENDER_THROTTLE_PER_ROAD_DISTANCE = {
	throttleSeconds = .05;
	roadDistance = 600;
}

local states = RoadBuilderState.GetStates()

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

	-- enable selection state, pauses resimulation of clientside roads (sent to the server)
	states.isPromptedSelection(true)

	-- selection prompt gui (while clearing the previous prompt guis)
	RoadBuilderVisualizer.ClearVisualizationData(RoadBuilderVisualizer.selectionDataContainer)
	local _, selectTriggeredSignal, undoTriggeredSignal, destructor = RoadBuilderVisualizer.AddSelectionPrompt(capturedStates.simulatedRoadPoint)

	-- when clicking the "select button"
	selectTriggeredSignal:Once(function()
		if states.selectedRoadPoint() then
			local selectedRoadPointCache: RoadPointCache.RoadPointCache = RoadBuilderEvents.RequestRoadData:InvokeServer(capturedStates.selectedRoadPoint.Position)

			RoadBuilderEvents.CreateRoadRequest:FireServer(
				capturedStates.currentRoadType,
				RoadVariantEnums.RoadExtension,
				PointVector2Data(capturedStates.selectedRoadPoint.Position, selectedRoadPointCache and selectedRoadPointCache.vector2Direction),
				PointVector2Data(capturedStates.simulatedRoadPoint.Position)
			)
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
				states.selectedRoadVector2Direction(DEFAULT_ROAD_POINT_AXIS)
			end
		end

		-- updated selectedroadpoint
		states.selectedRoadPoint(capturedStates.simulatedRoadPoint)

		destructor()
		states.isPromptedSelection(false)
	end)
	-- when clicking the "undo button"
	undoTriggeredSignal:Once(function()
		-- reset selectedroadpoint
		states.selectedRoadPoint(nil)

		destructor()
		states.isPromptedSelection(false)
	end)
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

RoadBuilderEvents.CreateRoadRequest.OnClientEvent:Connect(function(boolean, direction)
	states.selectedRoadVector2Direction(direction)
end)

local renderThrottle = 0
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

		-- dont create new visualization no raycastresult from mouse
		currentMouseCast = MouseUtils.GetMouseCast()
		if not currentMouseCast then
			return
		end
		
		local castPosition = currentMouseCast.Position
		local isCastInstanceValidSelection = RoadBuilderSelectionValidator.VerifyRoadPoint(currentMouseCast.Instance)

		if isCastInstanceValidSelection then
			states.simulatedRoadPoint(currentMouseCast.Instance)
		else
			local simulatedInstance: BasePart
			
			if capturedStates.selectedRoadPoint then
				local selectedRoadToMouseDistance = (capturedStates.selectedRoadPoint.Position - castPosition).Magnitude
				renderThrottle = selectedRoadToMouseDistance * (RENDER_THROTTLE_PER_ROAD_DISTANCE.throttleSeconds / RENDER_THROTTLE_PER_ROAD_DISTANCE.roadDistance)

				simulatedInstance = RoadBuilderVisualizer.SimulateRoadExtension(
					capturedStates.currentRoadType,
					PointVector2Data(
						capturedStates.selectedRoadPoint.Position, 
						states.selectedRoadVector2Direction()
					),
					PointVector2Data(castPosition)
				)
			else
				simulatedInstance = RoadBuilderVisualizer.SimulateRoadPoint(
					capturedStates.currentRoadType,
					PointVector2Data(castPosition)
				)
			end

			states.simulatedRoadPoint(simulatedInstance)
		end
	end
end)
