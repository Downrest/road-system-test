--[[
	HAVE A GUI SHOWING CURRENT SELECTED PART(S), lowkey imagining it to be at the
	left of ur screen, itll just show an icon of what u have selected and how many

	CTRL+D to deselect, or u can just drag the entire selection gui away from its position
	and it should just swiftly crash into the left side of the screen to show its being deselected

	when u press the build ui and press anywhere on the screen
		if ur mouse is on an existing road point
			that road point not selected? select
			already selected? unselect
		if ur mouse isnt, create + select that newly created road point

	this also applies for continuing to make roads, after every extension itll automatically
	have ur road selected lol. AND AGAIN, TO DESELECT JUST DO CTRL+D or whatnot
]]

local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")

local MouseUtils = require(StarterPlayer.StarterPlayerScripts.ClientUtils.MouseUtils)
local InputManager = require(StarterPlayer.StarterPlayerScripts.Inputs.InputManager)
local RoadBuilderState = require(StarterPlayer.StarterPlayerScripts.RoadBuilderClient.RoadBuilderState)
local RoadBuilderCreation = require(ReplicatedStorage.RoadBuilder.RoadBuilderCreation)
local RoadBuilderEnums = require(ReplicatedStorage.RoadBuilder.RoadBuilderEnums)
local RoadBuilderEvents = require(ReplicatedStorage.RoadBuilder.RoadBuilderEvents)

--// CONFIGURATION

local ROAD_SELECT_INPUT_TYPE = Enum.UserInputType.MouseButton1
local TASK_NAMES = {
	["RoadSelect"] = "RoadSelect";
}

--// VARIABLES
type RenderRoadData = {
	isRendering: boolean;
	selectedRoadVector2Data: RoadBuilderEnums.PointVector2Data;
}

local camera = workspace.CurrentCamera

local currentRoadType = Instance.new("StringValue")
local renderRoadData: RenderRoadData = {
	isRendering = false;
	selectedRoadVector2Data = nil;
}

--// RUNTIME

-- test
currentRoadType.Value = RoadBuilderEnums.RoadType.Mud

--[[
	triggering "road select", either
		no selected road, create road point
		selected road, select road point
]]
InputManager.OnPress:Connect(function()
    if RoadBuilderState.CurrentRoadType then
        local mouseRay = MouseUtils.GetMouseRay()
        RoadBuilderEvents.CreateRoad:FireServer(
            mouseRay, 
            currentRoadType.Value
        )
    end
end)

--[[
	ROAD VISUALIZATION
]]

--[[
	road visualization data, fired back after RoadBuilderEvents.CreateRoad:FireServer()
]]
RoadBuilderEvents.RenderRoad.OnClientEvent:Connect(function(
	renderState: boolean, 
	selectedRoadVector2Data: RoadBuilderEnums.PointVector2Data
)
	renderRoadData.isRendering = renderState
	renderRoadData.selectedRoadVector2Data = selectedRoadVector2Data
end)

--[[
	road visualization renderstep (uses RoadBuilderEnums.CreateType.Visualize)
]]
RunService.RenderStepped:Connect(function()
	local mouseCast = MouseUtils.GetMouseCast()

	if 
		not renderRoadData.isRendering
		or not mouseCast 
	then
		return
	end

	local selectedRoadVector2Data = renderRoadData.selectedRoadVector2Data
	local selectedRoadPosition = selectedRoadVector2Data.position
	local selectedRoadDirection = selectedRoadVector2Data.direction
	local selectedRoadYLevel = selectedRoadVector2Data.yLevel

	-- clear existing before new road visualization
	camera:ClearAllChildren()

	RoadBuilderCreation.CreateExtensionRoad(
		RoadBuilderCreation.RoadConfig(
			currentRoadType.Value, 
			RoadBuilderEnums.CreateType.Visualize,
			camera
		),

		RoadBuilderCreation.PointVector2Data(
			selectedRoadPosition, 
			selectedRoadDirection,
			selectedRoadYLevel
		),
		RoadBuilderCreation.PointVector2Data(mouseCast.Position)
	)
end)
