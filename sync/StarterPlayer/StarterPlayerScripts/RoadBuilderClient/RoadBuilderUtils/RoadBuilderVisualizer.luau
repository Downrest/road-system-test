local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local PlayerUtils = require(StarterPlayer.StarterPlayerScripts.ClientUtils.PlayerUtils)
local RoadBuilderCreation = require(ReplicatedStorage.RoadBuilder.RoadBuilderCreation)
local PointVector2Data = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.PointVector2Data)
local RoadConfigData = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.RoadConfigData)
local CreateTypeEnums = require(ReplicatedStorage.RoadBuilder.RoadBuilderEnums.CreateTypeEnums)
local RoadBuilderAssetGetter = require(ReplicatedStorage.RoadBuilder.RoadBuilderUtils.RoadBuilderAssetGetter)
local Signal = require(ReplicatedStorage.SharedPackages.Signal)

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

    return selectionGuiClone, selectTriggeredSignal, undoTriggeredSignal, destructor
end

--[[
    Creates a (simulated) road point, returning 1) a destructor function.

    The created road point is also indexed into `Visualizer.simulatedRoadContainer` with the returned values as its value.
]]
function Visualizer.SimulateRoadPoint(
    roadType: string,
    originVector2Data: PointVector2Data.PointVector2Data
): (Instance, DestructorFunction)
    local originRoadOutput = RoadBuilderCreation.CreateOriginRoad(
        RoadConfigData(
            roadType,
            CreateTypeEnums.Visualize,
            SELECTION_PARENT
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

]]
function Visualizer.SimulateRoadExtension(
    roadType: string,
    originVector2Data: PointVector2Data.PointVector2Data,
    goalVector2Data: PointVector2Data.PointVector2Data
): (BasePart, PointVector2Data.PointVector2Data, {BasePart}, DestructorFunction)
    local extensionRoadOutput = RoadBuilderCreation.CreateExtensionRoad(
        RoadConfigData(
            roadType,
            CreateTypeEnums.Visualize,
            SELECTION_PARENT
        ),
        
        originVector2Data,
        goalVector2Data
    )
    local endRoadPointInstance = extensionRoadOutput.endRoadPointInstance
    local endRoadPointVector2Data = extensionRoadOutput.endRoadPointVector2Data

    local dependentRoadInstances = extensionRoadOutput.dependentRoadInstances

    local function destructor()
		endRoadPointInstance:Destroy()
		for _, instance: BasePart in dependentRoadInstances do
			instance:Destroy()
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
