local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local GuiDragUtils = require(StarterPlayer.StarterPlayerScripts.ClientUtils.GuiDragUtils)
local PlayerUtils = require(StarterPlayer.StarterPlayerScripts.ClientUtils.PlayerUtils)
local RoadBuilderCreation = require(ReplicatedStorage.RoadBuilder.RoadBuilderCreation)
local PointVector2Data = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.PointVector2Data)
local RoadConfigData = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.RoadConfigData)
local CreateTypeEnums = require(ReplicatedStorage.RoadBuilder.RoadBuilderEnums.CreateTypeEnums)
local RoadBuilderAssetGetter = require(ReplicatedStorage.RoadBuilder.RoadBuilderAssetGetter)
local Signal = require(ReplicatedStorage.SharedPackages.Signal)
local branch = require(ReplicatedStorage.SharedPackages.Vide.branch)
local context = require(ReplicatedStorage.SharedPackages.Vide.context)
local TableUtils = require(ReplicatedStorage.SharedUtils.TableUtils)

local Visualizer = {}

local camera = workspace.CurrentCamera

local SELECTION_GUI_ASSET = RoadBuilderAssetGetter.guis.SelectionGui

--[[
    VISUALIZATION DATA
]]

type DestructorFunction = () -> ()
type VisualizationData = {
	destructor: DestructorFunction;
}
type SelectionAssetData = VisualizationData & {
    selectTriggeredSignal: Signal.Signal;
    undoTriggeredSignal: Signal.Signal;
}
type SimulatedRoadData = VisualizationData & {
    endRoadPointVector2Data: PointVector2Data.PointVector2Data
}

--[[
    VISUALIZATION CONTAINER
]]

type VisualizationContainer<Data> = {[Instance]: Data}

--// PUBLIC

Visualizer.selectionDataContainer = {}:: VisualizationContainer<SelectionAssetData>
Visualizer.simulatedRoadContainer = {}:: VisualizationContainer<SimulatedRoadData>

--[[
    HIGHLIGHTS
]]

local ROAD_POINT_HIGHLIGHT_LIMIT = 30

local SIMULATED_ROAD_MODEL = Instance.new("Model")
SIMULATED_ROAD_MODEL.Parent = camera

local VISUALIZE_ROAD_HIGHLIGHT_ASSET = RoadBuilderAssetGetter.highlights.VisualizeRoadHighlight
local VISUALIZE_ROAD_POINT_HIGHLIGHT_ASSET = RoadBuilderAssetGetter.highlights.VisualizeRoadPointHighlight

local simulatedRoadModelHighlight = VISUALIZE_ROAD_HIGHLIGHT_ASSET:Clone()
simulatedRoadModelHighlight.Parent = camera
simulatedRoadModelHighlight.Adornee = SIMULATED_ROAD_MODEL

local cachedRoadPointHighlights: {Highlight} = table.create(ROAD_POINT_HIGHLIGHT_LIMIT)
for _ = 1, ROAD_POINT_HIGHLIGHT_LIMIT do
    local highlight = VISUALIZE_ROAD_POINT_HIGHLIGHT_ASSET:Clone()
    highlight.Parent = camera
    table.insert(cachedRoadPointHighlights, highlight)
end

local function indexInstancesWithData(
    tableForIndex: {[any]: {any}},
    instancesToIndex: {Instance},
    data: {[string]: VisualizationData}
)
    for _, instance in instancesToIndex do
        tableForIndex[instance] = data
    end
end

function Visualizer.ClearVisualizationData(
    visualizationTable: VisualizationContainer<VisualizationData>
)
    for _, visualizationData in visualizationTable do
        visualizationData.destructor()
    end
end

type SelectTriggeredSignal = Signal.Signal
type UndoTriggeredSignal = Signal.Signal
type VerticalDragContinueSignal = Signal.Signal
type VerticalDragStartedSignal = Signal.Signal
type VerticalDragEndedSignal = Signal.Signal

type SelectionPromptSignals = {
    selectTriggered: SelectTriggeredSignal;
    undoTriggered: UndoTriggeredSignal;

    verticalDragContinue: VerticalDragContinueSignal;
    verticalDragStarted: VerticalDragStartedSignal;
    verticalDragEnded: VerticalDragEndedSignal;
}

--[[
    Creates a selection prompt parented to `adornee` parameter, returning 1) select-triggered signal, 2) undo-triggered signal, and 3) destructor function.

    The created selection prompt is also indexed into `Visualizer.selectionDataContainer`.
]]
function Visualizer.AddSelectionPrompt(adornee: BasePart): (
    Instance, SelectionPromptSignals, DestructorFunction
)
    
	local selectionGuiClone = SELECTION_GUI_ASSET:Clone()
    selectionGuiClone.Parent = PlayerUtils.playerGui
    selectionGuiClone.Adornee = adornee

    local confirmationFrame = selectionGuiClone.Confirmation
    local selectButton = confirmationFrame.Select
    local undoButton = confirmationFrame.Undo

    local selectTriggeredSignal = Signal.new()
    selectButton.MouseButton1Down:Connect(function()
        selectTriggeredSignal:Fire()
    end)

    local undoTriggeredSignal = Signal.new()
    undoButton.MouseButton1Down:Connect(function()
        undoTriggeredSignal:Fire()
    end)

    local movementFrame = selectionGuiClone.Movement
    local verticalHandle = movementFrame.VerticalHandle

    local verticalGuiDrag, verticalGuiDragDestructor = GuiDragUtils.new(verticalHandle)
    local verticalDragContinueSignal = verticalGuiDrag.DragContinueSignal
    local verticalDragStartedSignal = verticalGuiDrag.DragStartedSignal
    local verticalDragEndedSignal = verticalGuiDrag.DragEndedSignal

    local function destructor()
        selectionGuiClone:Destroy()
        selectTriggeredSignal:Destroy()
		undoTriggeredSignal:Destroy()
        verticalGuiDragDestructor()
		Visualizer.selectionDataContainer[selectionGuiClone] = nil
    end

    indexInstancesWithData(
        Visualizer.selectionDataContainer,
        {selectionGuiClone},
        {
            selectTriggeredSignal = selectTriggeredSignal;
            undoTriggeredSignal = undoTriggeredSignal;
            destructor = destructor;
        }
    )

    return 
        selectionGuiClone, 
        {
            selectTriggered = selectTriggeredSignal;
            undoTriggered = undoTriggeredSignal;

            verticalDragContinue = verticalDragContinueSignal;
            verticalDragStarted = verticalDragStartedSignal;
            verticalDragEnded = verticalDragEndedSignal;
        },
        destructor
end

--[[
    Creates a (simulated) road point, returning a destructor function.

     The created road point is also indexed into `Visualizer.simulatedRoadContainer`.
]]
function Visualizer.SimulateRoadPoint(
    roadType: string,
    originVector2Data: PointVector2Data.PointVector2Data
): (Instance, DestructorFunction)
    local originRoadOutput = RoadBuilderCreation.CreateOriginRoad(
        RoadConfigData(
            roadType,
            CreateTypeEnums.Visualize,
            camera
        ),

        originVector2Data
    )
    local originRoadPointInstance = originRoadOutput.endRoadPointInstance

    local function destructor()
		originRoadPointInstance:Destroy()
		Visualizer.simulatedRoadContainer[originRoadPointInstance] = nil
    end

    indexInstancesWithData(
        Visualizer.simulatedRoadContainer,
        {originRoadPointInstance},
        {
            destructor = destructor;
        }
    )

    return originRoadPointInstance, destructor
end

--[[
    Attaches `cachedRoadPointHighlights[1]` to `roadPoint`.
]]
function Visualizer.AttachRoadPointHighlight(roadPoint: BasePart)
    cachedRoadPointHighlights[1].Adornee = roadPoint
end

--[[
    Unattaches `cachedRoadPointHighlights[1]` to any road point.
]]
function Visualizer.UnattachRoadPointHighlight()
    cachedRoadPointHighlights[1].Adornee = nil
end

--[[
    Creates a (simulated) road extension, returning a destructor function.

    The created road extension is also indexed into `Visualizer.simulatedRoadContainer`.
]]
function Visualizer.SimulateRoadExtension(
    roadType: string,
    originVector2Data: PointVector2Data.PointVector2Data,
    goalVector2Data: PointVector2Data.PointVector2Data
): (BasePart, PointVector2Data.PointVector2Data, {BasePart}, DestructorFunction)
    local originRoadPointOutput = RoadBuilderCreation.CreateOriginRoad(
        RoadConfigData(
            roadType,
            CreateTypeEnums.Visualize,
            camera
        ),

        originVector2Data
    )
    local extensionRoadOutput = RoadBuilderCreation.CreateExtensionRoad(
        RoadConfigData(
            roadType,
            CreateTypeEnums.Visualize,
            SIMULATED_ROAD_MODEL
        ),
        
        originVector2Data,
        goalVector2Data
    )
    local endRoadPointInstance = extensionRoadOutput.endRoadPointInstance
    local endRoadPointVector2Data = extensionRoadOutput.endRoadPointVector2Data

    local dependentRoadInstances = extensionRoadOutput.dependentRoadInstances
    table.insert(dependentRoadInstances.roadPoints, originRoadPointOutput.endRoadPointInstance) -- extra line to insert originRoadPoint

    --[[
        add highlights from the very goal till the origin (prioritizing closest to player)
        highlights are only limited to `ROAD_POINT_HIGHLIGHT_LIMIT`
    ]]
    for i = #dependentRoadInstances.roadPoints, 1, -1 do
        local roadPoint = dependentRoadInstances.roadPoints[i]
        local highlight = cachedRoadPointHighlights[(#dependentRoadInstances.roadPoints+1) - i]

        if highlight then
            highlight.Adornee = roadPoint
        else
            break
        end
    end

    local function destructor()
		endRoadPointInstance:Destroy()
		for _, roadPoint in dependentRoadInstances.roadPoints do
            roadPoint:Destroy()
        end
        for _, road in dependentRoadInstances.roads do
            road:Destroy()
        end
		Visualizer.simulatedRoadContainer[endRoadPointInstance] = nil
    end

    indexInstancesWithData(
        Visualizer.simulatedRoadContainer,
        {endRoadPointInstance},
        {
            endRoadPointVector2Data = endRoadPointVector2Data;
			destructor = destructor;
        }
    )

    return endRoadPointInstance, endRoadPointVector2Data, dependentRoadInstances, destructor
end

return Visualizer
