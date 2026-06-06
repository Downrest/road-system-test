local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local VisualizerClass = require(StarterPlayer.StarterPlayerScripts.ClientClasses.VisualizerClass)
local RoadBuilderCreation = require(ReplicatedStorage.RoadBuilder.RoadBuilderCreation)
local PointVector2Data = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.PointVector2Data)
local RoadConfigData = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.RoadConfigData)
local CreateTypeEnums = require(ReplicatedStorage.RoadBuilder.RoadBuilderEnums.CreateTypeEnums)
local RoadBuilderAssetGetter = require(ReplicatedStorage.RoadBuilder.RoadBuilderAssetGetter)

type DestructorFunction = () -> ()
type SimulatedRoadData = {
    endRoadPointVector2Data: PointVector2Data.PointVector2Data;
    destructor: DestructorFunction
}

local RoadSimulation = VisualizerClass.new<<SimulatedRoadData>>()

local camera = workspace.CurrentCamera

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

local focusHighlight = VISUALIZE_ROAD_POINT_HIGHLIGHT_ASSET:Clone()
focusHighlight.Parent = camera

local roadPointHighlightsCache: {Highlight} = table.create(ROAD_POINT_HIGHLIGHT_LIMIT)
for _ = 1, ROAD_POINT_HIGHLIGHT_LIMIT do
    local highlight = VISUALIZE_ROAD_POINT_HIGHLIGHT_ASSET:Clone()
    highlight.Parent = camera
    table.insert(roadPointHighlightsCache, highlight)
end

function RoadSimulation.ClearVisualizedRoads(...)
    return RoadSimulation:ClearVisualizedCache(...)
end

--[[
    Attaches `roadPointHighlightsCache[1]` to `roadPoint`.
]]
function RoadSimulation.AttachFocusHighlight(roadPoint: BasePart)
    focusHighlight.Adornee = roadPoint
end

--[[
    Unattaches `roadPointHighlightsCache[1]` to any road point.
]]
function RoadSimulation.UnattachFocusHighlight()
    focusHighlight.Adornee = nil
end

--[[
    Creates a (simulated) road point, returning a destructor function.

     The created road point is also indexed into `simulatedRoadCache`.
]]
function RoadSimulation.SimulateRoadPoint(
    roadType: string,
    originVector2Data: PointVector2Data.PointVector2Data,
    avoidCaching: boolean?
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
		RoadSimulation.visualizerCache[originRoadPointInstance] = nil
    end

    if not avoidCaching then
        RoadSimulation:CacheInstancesWithData(
            {originRoadPointInstance},
            {
                destructor = destructor;
            }
        )
    end

    return originRoadPointInstance, destructor
end

--[[
    Creates a (simulated) road extension, returning a destructor function.

    The created road extension is also indexed into `simulatedRoadCache`.
]]
function RoadSimulation.SimulateRoadExtension(
    roadType: string,
    originVector2Data: PointVector2Data.PointVector2Data,
    goalVector2Data: PointVector2Data.PointVector2Data,
    avoidCaching: boolean?
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

    local allRoadPoints = table.move(dependentRoadInstances.roadPoints, 1, #dependentRoadInstances.roadPoints, 2, {endRoadPointInstance})
    local allRoadPointsAmount = #allRoadPoints

    --[[
        add highlights from the very goal till the origin (prioritizing closest to player)
        highlights are only limited to `ROAD_POINT_HIGHLIGHT_LIMIT`
    ]]
    for i = allRoadPointsAmount, 1, -1 do
        local roadPoint = allRoadPoints[i]
        local highlight = roadPointHighlightsCache[(allRoadPointsAmount+1) - i]

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
		RoadSimulation.visualizerCache[endRoadPointInstance] = nil
    end

    if not avoidCaching then
        RoadSimulation:CacheInstancesWithData(
            {endRoadPointInstance},
            {
                endRoadPointVector2Data = endRoadPointVector2Data;
                destructor = destructor;
            }
        )
    end

    return endRoadPointInstance, endRoadPointVector2Data, dependentRoadInstances, destructor
end

return RoadSimulation
