local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")
local Stats = game:GetService("Stats")

local RoadBuilderCreation = require(ReplicatedStorage.RoadBuilder.RoadBuilderCreation)
local RoadPointCache = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.CacheDataWrappers.RoadPointCache)
local CreateRoadConfig = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.CreateRoadConfig)
local OverrideRoadConfig = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.OverrideRoadConfig)
local PointVector2Data = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.PointVector2Data)
local RoadVariantEnums = require(ReplicatedStorage.RoadBuilder.RoadBuilderEnums.RoadVariantEnums)
local MouseUtils = require(StarterPlayer.StarterPlayerScripts.ClientUtils.MouseUtils)
local RoadBuilderEvents = require(ReplicatedStorage.RoadBuilder.RoadBuilderEvents)
local RoadBuilderSelectionValidator = require(ReplicatedStorage.RoadBuilder.RoadBuilderUtils.RoadBuilderSelectionValidator)
local Janitor = require(ReplicatedStorage.SharedPackages.Janitor)
local Vide = require(ReplicatedStorage.SharedPackages.Vide)
local InputManager = require(StarterPlayer.StarterPlayerScripts.Inputs.InputManager)
local RemakeTypeEnum = require(StarterPlayer.StarterPlayerScripts.RoadBuilderClient.RoadBuilderEnums.RemakeTypeEnum)
local RoadBuilderState = require(StarterPlayer.StarterPlayerScripts.RoadBuilderClient.RoadBuilderState)
local RoadBuilderRoadSimulation = require(StarterPlayer.StarterPlayerScripts.RoadBuilderClient.RoadBuilderUtils.RoadBuilderRoadSimulation)
local RoadBuilderSelectionPrompt = require(StarterPlayer.StarterPlayerScripts.RoadBuilderClient.RoadBuilderUtils.RoadBuilderSelectionPrompt)

type RemakeState = {
	isRemaking: boolean;
	remakeType: RemakeTypeEnum.RemakeTypeEnum?;

	wasEverRemaked: boolean;
}
type RemakeRoadData = {
	roadInstance: BasePart;
	roadColor: Color3;
}

local REMAKE_ROAD_COLOR = Color3.new(0.282353, 0.313725, 0.870588)
local RENDER_THROTTLE_PER_ROAD_DISTANCE = {
	throttleSeconds = .05;
	roadverticalDistance = 600;
}
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
	selectionRoadPoint = (nil):: BasePart?;
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

-- local function toggleGoalPointVisibility(isVisible: boolean)
-- 	local goalPoint = Vide.untrack(states.currentGoalPoint).goalPoint

-- 	-- can be nil, mostly because of how Vide effects work
-- 	if goalPoint then
-- 		goalPoint.Transparency = isVisible and 0 or 1
-- 	end
-- end

local function exitFinalizedSelection(janitor: Janitor.Janitor)
	janitor:Cleanup()
	toggleFinalizedSelectionGui(false)
	
	RoadBuilderState.SetMovingSelection(false, false)
	
	states.isPromptedSelection(false)
	onPressDebounce = false
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

local function toggleRemakeRoadsCache(isVisible: boolean)
	-- warn(currentRemakeRoadCache.dependentRoads)
	-- warn(`isvisible: {isVisible}`)
	for _, remakeRoadData in currentRemakeRoadCache.dependentRoads do
		remakeRoadData.roadInstance.Color = isVisible 
			and remakeRoadData.roadColor 
			or REMAKE_ROAD_COLOR
		remakeRoadData.roadInstance.Transparency = isVisible and 0 or .5
	end
end

local function cacheRemakeRoads(capturedStates: RoadBuilderState.CapturedStates)
	-- check if current goalpoint has any cache, otherwise return
	local goalPointCache: RoadPointCache.RoadPointCache = RoadBuilderEvents.RequestRoadData:InvokeServer(capturedStates.currentGoalPoint.goalPoint.Position)
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

	-- loop through road points, and ensure that direction data is reflected for visualization accuracy
	for _, endRoadPoint in goalPointCache.pairExtensionEndRoadPoints do
		warn(`TRYING TO EXTENSION ROAD: {endRoadPoint.Position}`)
		local endRoadPointCache: RoadPointCache.RoadPointCache = RoadBuilderEvents.RequestRoadData:InvokeServer(endRoadPoint.Position)
		if not endRoadPointCache then
			continue
		end
		
		currentRemakeRoadCache.endRoadPoints[endRoadPoint] = {
			direction = endRoadPointCache.vector2Direction;
		}
	end
end

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

local function requestRoadCreation(createRoadConfig: CreateRoadConfig.CreateRoadConfig)
	RoadBuilderEvents.CreateRoadRequest:FireServer(createRoadConfig)
end

local function resetRenderThrottle()
	renderThrottle = 0
end

local function updateRemakingStatus(
	remakeState: RemakeState,
	isRemaking: boolean,
	remakeType: RemakeTypeEnum.RemakeTypeEnum
)
	remakeState.isRemaking = isRemaking
	remakeState.remakeType = remakeType
end

local function refreshCapturedStates(capturedStates: RoadBuilderState.CapturedStates)
	capturedStates = RoadBuilderState.CaptureStates()
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

	-- enable selection state, pauses resimulation of clientside roads (sent to the server)
	states.isPromptedSelection(true)

	resetRenderThrottle()
	RoadBuilderState.ResetStates("IsMovingSelection")

	warn(capturedStates.currentGoalPoint.goalPoint.Position)
	-- prepare remakecache incase of "remake movement"
	clearRemakeRoadsCache()
	cacheRemakeRoads(capturedStates)

	--[[
		make the final road visualization (if applicable)
		just to fix up anything that may have been missed from the renderstep
	]]
	if capturedStates.currentSelectionPoint.selectionPoint then
		RoadBuilderRoadSimulation.ClearVisualizedRoads(
			{capturedStates.currentGoalPoint.goalPoint}
		)
		visualizeStandardRoad(capturedStates)
	end

	-- selection prompt gui
	toggleFinalizedSelectionGui(true)
	attachSelectionGui(capturedStates.currentGoalPoint.goalPoint)

	--[[
		MOVEMENT SIGNALS
	]]

	local previousVerticalRay = MouseUtils.GetMouseRay()

	--TODO: theres an issue where sometimes when u click the resetStarted, it also registers verticaldragstarted which is eh ghsdhsdh
	-- vertical remake
	onPressJanitor:Add(SELECTION_GUI_SIGNALS.verticalDragContinue:Connect(function()
		if remakeState.isRemaking and remakeState.remakeType ~= RemakeTypeEnum.Vertical then
			return
		end
		warn("VERTICAL ONGOING")

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
		warn("VERTICAL STARTED")

		remakeState.wasEverRemaked = true
		previousVerticalRay = MouseUtils.GetMouseRay()
		toggleRemakeRoadsCache(false)
		RoadBuilderState.SetMovingSelection(true, true)
		warn(states.isMovingSelection().isCustomPosition)
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
		warn("VERTICAL ENDED")

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
		
		warn("FREEMOVE STARTED")

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

		warn("FREEMOVE ENDED")
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
			if 
				capturedStates.currentSelectionPoint.selectionPoint.Position 
				~= capturedStates.currentGoalPoint.goalPoint.Position 
			then
				warn(`OH NEW ROAD EXTENSION!:`, currentRemakeRoadCache.dependentRoads, `and`, currentRemakeRoadCache.endRoadPoints)
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
			if capturedStates.isHoveringExistingRoadPoint then
				if remakeState.wasEverRemaked then
					--[[
						modify EXISTING ROAD EXTENSION (and override old road extension), 
						interacts with `currentRemakeRoadCache` which is modified by "remake movement"
					]]
					warn(`OH EXISTING ROAD EXTENSION!:`, currentRemakeRoadCache.dependentRoads, `and`, currentRemakeRoadCache.endRoadPoints)
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

					warn("CLEAR REMAKE ROADS CACHE")
					clearRemakeRoadsCache()
				end
			else
				local goalRoadPointCache: RoadPointCache.RoadPointCache = RoadBuilderEvents.RequestRoadData:InvokeServer(capturedStates.currentGoalPoint.goalPoint.Position)

				--[[
					if road point has existed and has cache, update direction state to cached direction
				]]
				if goalRoadPointCache then
					warn(`OH im uh... setting direction only, no creation`)
					RoadBuilderState.SetCurrentSelectionDirection(goalRoadPointCache.vector2Direction)

				--[[
					otherwise, NEW ROAD POINT with direction state updated to `DEFAULT_ROAD_POINT_AXIS`
				]]
				else
					warn(`OH NEW ROAD POINT!:`, currentRemakeRoadCache.dependentRoads, `and`, currentRemakeRoadCache.endRoadPoints)
					requestRoadCreation(
						CreateRoadConfig(
							capturedStates.currentRoadType,
							RoadVariantEnums.RoadPoint,
							nil,

							PointVector2Data(capturedStates.currentGoalPoint.goalPoint.Position)
						)
					)
					RoadBuilderState.SetCurrentSelectionDirection(RoadBuilderCreation.DEFAULT_ROAD_POINT_AXIS)
				end
			end
		end

		toggleRemakeRoadsCache(true)

		-- updated selectedroadpoint
		RoadBuilderState.SetCurrentSelectionPoint(capturedStates.currentGoalPoint.goalPoint)

		-- do not create a new goalpoint if `isRepeatedSelection` is true
		if not isRepeatedSelection then
			local newSimulatedRoadPoint = newRoadPointOnMouse(capturedStates.currentGoalPoint.goalPoint.Position)
			RoadBuilderState.SetCurrentGoalPoint(newSimulatedRoadPoint)
		end

		exitFinalizedSelection(onPressJanitor)
	end))

	-- when clicking the "undo button"
	onPressJanitor:Add(SELECTION_GUI_SIGNALS.undoTriggered:Once(function()
		refreshCapturedStates(capturedStates)

		-- reset selectedroadpoint
		RoadBuilderState.SetCurrentSelectionPoint(nil)
		RoadBuilderRoadSimulation.AttachFocusHighlight(capturedStates.currentGoalPoint.goalPoint)

		-- -- undo any "remake movement"
		toggleRemakeRoadsCache(true)

		exitFinalizedSelection(onPressJanitor)
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

	-- Vide.effect(function()
	-- 	warn(states.currentGoalPoint().goalPoint.Position)
	-- end)
end)

-- whenever a new road is built on the server, this is fired back to the client for road visualization "correction"
RoadBuilderEvents.CreateRoadRequest.OnClientEvent:Connect(function(boolean, direction)
	RoadBuilderState.SetCurrentSelectionDirection(direction)
end)

local function moveCurrentGoalPoint(position: Vector3)
	states.currentGoalPoint().goalPoint.Position = position
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
		-- warn(`ispromptedslel: {capturedStates.isPromptedSelection} ismoving: {capturedStates.isMovingSelection.isMoving}`)
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

		--[[
			checks if instance has been actually cached, 
			our way of doublechecking if a roadpoint is merely a visualization or not
		]]
		local isCastInstanceValidSelection = RoadBuilderSelectionValidator.VerifyRoadPoint(currentMouseCast.Instance)

		-- moving existing road point (and, if applicable, override connected roads via visualizeRemakeRoad())
		if 
			capturedStates.isHoveringExistingRoadPoint
			and capturedStates.isMovingSelection.isMoving
			and not capturedStates.currentSelectionPoint.selectionPoint
			-- -- this implies the current goalpoint has no cached roads, therefore its in the process of being created
			-- and #currentRemakeRoadCache.dependentRoads > 0 
		then
			visualizeRemakeRoad(capturedStates)

			-- normal move-to-cursor, examples of `isCustomPosition` is vertical movement
			if not states.isMovingSelection().isCustomPosition then
				moveCurrentGoalPoint(mouseCastPosition)
			end

		-- moving visualized road point (and, if applicable, create connected roads via visualizeStandardRoad())
		else
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
			if not states.isMovingSelection().isCustomPosition then
				moveCurrentGoalPoint(goalPosition)
			end

			-- either existing instance or nil
			RoadBuilderState.SetCurrentGoalReference(isSelectingExistingRoad and currentMouseCast.Instance)
		end

		handleRenderThrottling(capturedStates)

		states.isVisualizing(true)
	end
end)
