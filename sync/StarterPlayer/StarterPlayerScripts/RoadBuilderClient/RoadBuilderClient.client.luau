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

local RoadBuilderCreation = require(ReplicatedStorage.RoadBuilder.RoadBuilderCreation)
local PointVector2Data = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.PointVector2Data)
local RoadConfigData = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.RoadConfigData)
local CreateTypeEnums = require(ReplicatedStorage.RoadBuilder.RoadBuilderEnums.CreateTypeEnums)
local RoadTypeEnums = require(ReplicatedStorage.RoadBuilder.RoadBuilderEnums.RoadTypeEnums)
local MouseUtils = require(StarterPlayer.StarterPlayerScripts.ClientUtils.MouseUtils)
local RoadBuilderEvents = require(ReplicatedStorage.RoadBuilder.RoadBuilderEvents)
local RoadBuilderSelectionValidator = require(ReplicatedStorage.RoadBuilder.RoadBuilderUtils.RoadBuilderSelectionValidator)
local CharmState = require(ReplicatedStorage.SharedUtils.CharmState)
local InputManager = require(StarterPlayer.StarterPlayerScripts.Inputs.InputManager)
local RoadBuilderState = require(StarterPlayer.StarterPlayerScripts.RoadBuilderClient.RoadBuilderState)
local RoadBuilderVisualizer = require(StarterPlayer.StarterPlayerScripts.RoadBuilderClient.RoadBuilderUtils.RoadBuilderVisualizer)

local isInBuildMenuState = RoadBuilderState.IsInBuildMenu
local currentRoadTypeState = RoadBuilderState.CurrentRoadType
local selectedRoadPointState = RoadBuilderState.SelectedRoadPoint
local simulatedRoadPointState = RoadBuilderState.SimulatedRoadPoint
local isPromptedSelection = RoadBuilderState.IsPromptedSelection

local currentMouseCast: RaycastResult

--[[
	client merely sends requests to the server
	to prompt road creation
]]
InputManager.OnPress:Connect(function()
	if 
		not isInBuildMenuState() 
		or not simulatedRoadPointState()
	then
		return
	end

	selectedRoadPointState(simulatedRoadPointState())
	isPromptedSelection(true)
	local _, selectTriggeredSignal, undoTriggeredSignal, destructor = RoadBuilderVisualizer.AddSelectionPrompt(simulatedRoadPointState())

	selectTriggeredSignal:Connect(function()
		destructor()
		RoadBuilderEvents.CreateRoadRequest:FireServer(
			simulatedRoadPointState().Position, 
			currentRoadTypeState()
		)

		task.wait()
		isPromptedSelection(false)
	end)
	undoTriggeredSignal:Connect(function()
		isPromptedSelection(false)
		destructor()
		selectedRoadPointState(nil)
	end)
end)

--[[
	if state is exited (meaning player is no longer in build menu)
	clear selected road data on the server
]]
CharmState.subscribe(isInBuildMenuState, function()
	-- RoadBuilderEvents.ClearSelectedRoadRequest:FireServer()
	RoadBuilderVisualizer.ClearVisualizationData(RoadBuilderVisualizer.simulatedRoadContainer)
	selectedRoadPointState(nil)
end)

--[[
	if road request (CreateRoadRequest:FireServer()) is successful,
	server returns data to the client for visualization purposes
]]
-- RoadBuilderEvents.CreateRoadRequest.OnClientEvent:Connect(function(
-- 	createSuccess: boolean,
-- 	createdRoad: BasePart
-- )
-- 	selectedRoadPointState(createdRoad)
-- end)

RunService.RenderStepped:Connect(function()
	-- has selected? prevent clearing of visualized road
	if isPromptedSelection() then
		return

	-- else, continue with visualization rerender
	else
		-- clear current visualization data
		RoadBuilderVisualizer.ClearVisualizationData(RoadBuilderVisualizer.simulatedRoadContainer)

		-- dont create new visualization if not in build menu
		if not isInBuildMenuState() then
			return
		end

		-- dont create new visualization no raycastresult from mouse
		currentMouseCast = MouseUtils.GetMouseCast()
		if not currentMouseCast then
			return
		end

		local isCastInstanceValidSelection = RoadBuilderSelectionValidator.VerifyRoadPoint(currentMouseCast.Instance)

		if isCastInstanceValidSelection then
			warn("SELECTING SOMETHINGG")
			simulatedRoadPointState(currentMouseCast.Instance)
		else
			local castPosition = currentMouseCast.Position

			local instance = RoadBuilderVisualizer.SimulateRoadPoint(
				currentRoadTypeState(),
				castPosition
			)
			simulatedRoadPointState(instance)
		end
	end
end)
