--[[
	steps
		hover on something
		click
		visualization stops moving, assuming ur "finalizing ur selection"
		either / or X shows up
			click / and itll build
			click X and itll let u keep moving the selection
]]

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
		not capturedStates.isInBuildMenuState
		or not capturedStates.simulatedRoadPointState
	then
		return
	end

	-- just incase
	RoadBuilderVisualizer.ClearVisualizationData(RoadBuilderVisualizer.selectionDataContainer)

	--[[
		enable selection state, pauses resimulation of clientside roads (sent to the server)
	]]
	states.isPromptedSelectionState(true)
	local _, selectTriggeredSignal, undoTriggeredSignal, destructor = RoadBuilderVisualizer.AddSelectionPrompt(capturedStates.simulatedRoadPointState)

	selectTriggeredSignal:Once(function()
		local simulatedRoadPointData: RoadPointCache.type = RoadBuilderEvents.RequestRoadData:InvokeServer(capturedStates.simulatedRoadPointState.Position)
		
		if simulatedRoadPointData then
			states.selectedRoadVector2Direction(simulatedRoadPointData.vector2Direction)
		else
				-- road extension
			if states.selectedRoadPointState() then
				local selectedRoadPointData: RoadPointCache.type = RoadBuilderEvents.RequestRoadData:InvokeServer(capturedStates.selectedRoadPointState.Position)

				warn(`STARTS WITH: {selectedRoadPointData and tostring(selectedRoadPointData.vector2Direction)}`)
				RoadBuilderEvents.CreateRoadRequest:FireServer(
					capturedStates.currentRoadTypeState,
					RoadVariantEnums.RoadExtension,
					PointVector2Data(capturedStates.selectedRoadPointState.Position, selectedRoadPointData and selectedRoadPointData.vector2Direction),
					PointVector2Data(capturedStates.simulatedRoadPointState.Position)
				)

				-- local selectedRoadPointData: RoadPointCache.type = RoadBuilderEvents.RequestRoadData:InvokeServer(capturedStates.simulatedRoadPointState.Position)
				-- warn(`new selection: {selectedRoadPointData and tostring(selectedRoadPointData.vector2Direction)}`)
				-- if selectedRoadPointData then
				-- 	states.selectedRoadVector2Direction(selectedRoadPointData.vector2Direction)
				-- end

			-- road point
			else
				RoadBuilderEvents.CreateRoadRequest:FireServer(
					capturedStates.currentRoadTypeState,
					RoadVariantEnums.RoadPoint,
					PointVector2Data(capturedStates.simulatedRoadPointState.Position)
				)
			end
		end

		states.selectedRoadPointState(capturedStates.simulatedRoadPointState)

		destructor()
		states.isPromptedSelectionState(false)
	end)
	undoTriggeredSignal:Once(function()
		states.selectedRoadPointState(nil)

		destructor()
		states.isPromptedSelectionState(false)
	end)
end)

--[[
	if state is exited (meaning player is no longer in build menu)
	clear selected road data
]]
RoadBuilderState.Effect(function()
	if not states.isInBuildMenuState() then
		RoadBuilderVisualizer.ClearVisualizationData(RoadBuilderVisualizer.simulatedRoadContainer)
		RoadBuilderVisualizer.ClearVisualizationData(RoadBuilderVisualizer.selectionDataContainer)
		RoadBuilderState.ResetStates()
	end
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
		not capturedStates.isInBuildMenuState
		or capturedStates.isPromptedSelectionState
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
			states.simulatedRoadPointState(currentMouseCast.Instance)
		else
			local simulatedInstance: BasePart
			
			if capturedStates.selectedRoadPointState then
				local selectedRoadToMouseDistance = (capturedStates.selectedRoadPointState.Position - castPosition).Magnitude
				renderThrottle = selectedRoadToMouseDistance * (RENDER_THROTTLE_PER_ROAD_DISTANCE.throttleSeconds / RENDER_THROTTLE_PER_ROAD_DISTANCE.roadDistance)

				simulatedInstance = RoadBuilderVisualizer.SimulateRoadExtension(
					capturedStates.currentRoadTypeState,
					PointVector2Data(
						capturedStates.selectedRoadPointState.Position, 
						states.selectedRoadVector2Direction()
					),
					PointVector2Data(castPosition)
				)
			else
				simulatedInstance = RoadBuilderVisualizer.SimulateRoadPoint(
					capturedStates.currentRoadTypeState,
					PointVector2Data(castPosition)
				)
			end

			states.simulatedRoadPointState(simulatedInstance)
		end
	end
end)
