local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local PlayerUtils = require(StarterPlayer.StarterPlayerScripts.ClientUtils.PlayerUtils)
local RoadBuilderCreation = require(ReplicatedStorage.RoadBuilder.RoadBuilderCreation)
local PointVector2Data = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.PointVector2Data)
local RoadConfigData = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.RoadConfigData)
local CreateTypeEnums = require(ReplicatedStorage.RoadBuilder.RoadBuilderEnums.CreateTypeEnums)
local RoadBuilderAssetGetter = require(ReplicatedStorage.RoadBuilder.RoadBuilderUtils.RoadBuilderAssetGetter)
local Signal = require(ReplicatedStorage.SharedUtils.Signal)

local Visualizer = {}

local camera = workspace.CurrentCamera

local SELECTION_PARENT = Instance.new("Folder")
SELECTION_PARENT.Name = "SimulatedRoads"
SELECTION_PARENT.Parent = camera

local SELECTION_GUI_ASSET = RoadBuilderAssetGetter.guis.SelectionGui

--[[
    VISUALIZATION DATA
]]

type DestructorFunction = () -> ()
type VisualizationData = {
    destructor: DestructorFunction;
    [string]: any
}
type SelectionAssetData = VisualizationData & {
    selectTriggeredSignal: Signal.Signal;
    undoTriggeredSignal: Signal.Signal;
}
type SimulatedRoadData = VisualizationData

--[[
    VISUALIZATION CONTAINER
]]

type VisualizationContainer<Data> = {[Instance]: Data}

--// PUBLIC

Visualizer.selectionDataContainer = {}:: VisualizationContainer<SelectionAssetData>
Visualizer.simulatedRoadContainer = {}:: VisualizationContainer<SimulatedRoadData>

local function indexInstanceWithData(
    tableForIndex: {[any]: {any}},
    instanceToIndex: Instance,
    data: {[string]: VisualizationData}
)
    tableForIndex[instanceToIndex] = data
end

function Visualizer.ClearVisualizationData(
    visualizationTable: VisualizationContainer<VisualizationData>
)
    for _, visualizationData in visualizationTable do
        visualizationData.destructor()
    end
end

--[[
    Creates a selection prompt parented to `adornee` parameter, returning 1) select-triggered signal, 2) undo-triggered signal, and 3) destructor function.

    The created selection prompt is also indexed into `Visualizer.selectionDataContainer` with the returned values as its value.
]]
function Visualizer.AddSelectionPrompt(adornee: BasePart): (
    Instance, Signal.Signal, Signal.Signal, DestructorFunction
)
	local selectionGuiClone = SELECTION_GUI_ASSET:Clone()
    selectionGuiClone.Parent = PlayerUtils.playerGui
    selectionGuiClone.Adornee = adornee

    local selectButton = selectionGuiClone.Select
    local undoButton = selectionGuiClone.Undo

    local selectTriggeredSignal = Signal.new()
    selectButton.MouseButton1Down:Connect(function()
        selectTriggeredSignal:Fire()
    end)

    local undoTriggeredSignal = Signal.new()
    undoButton.MouseButton1Down:Connect(function()
        undoTriggeredSignal:Fire()
    end)

    local function destructor()
        selectionGuiClone:Destroy()
        selectTriggeredSignal:Destroy()
        undoTriggeredSignal:Destroy()
    end

    indexInstanceWithData(
        Visualizer.selectionDataContainer,
        selectionGuiClone,
        {
            selectTriggeredSignal = selectTriggeredSignal;
            undoTriggeredSignal = undoTriggeredSignal;
            destructor = destructor;
        }
    )

    return selectionGuiClone, selectTriggeredSignal, undoTriggeredSignal, destructor
end

--[[
    Creates a (simulated) road point, returning 1) a destructor function.

    The created road point is also indexed into `Visualizer.simulatedRoadContainer` with the returned values as its value.
]]
function Visualizer.SimulateRoadPoint(
    roadType: string,
    position: Vector3
): (
    Instance, DestructorFunction
)
    local originRoadOutput = RoadBuilderCreation.CreateOriginRoad(
        RoadConfigData(
            roadType,
            CreateTypeEnums.Visualize,
            SELECTION_PARENT
        ),

        PointVector2Data(position)
    )

    local function destructor()
        originRoadOutput.endRoadInstance:Destroy()
    end

    indexInstanceWithData(
        Visualizer.simulatedRoadContainer,
        originRoadOutput.endRoadInstance,
        {
            destructor = destructor;
        }
    )

    return originRoadOutput.endRoadInstance, destructor
end

return Visualizer
