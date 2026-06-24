local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local VisualizerClass = require(StarterPlayer.StarterPlayerScripts.ClientClasses.VisualizerClass)
local RoadVisualizationConfig = require(StarterPlayer.StarterPlayerScripts.RoadBuilderClient.RoadBuilderConfig.RoadVisualizationConfig)
local RoadExtensionVisualData = require(StarterPlayer.StarterPlayerScripts.RoadBuilderClient.RoadBuilderDataWrappers.VisualizationWrappers.RoadExtensionVisualData)
local RoadPointVisualData = require(StarterPlayer.StarterPlayerScripts.RoadBuilderClient.RoadBuilderDataWrappers.VisualizationWrappers.RoadPointVisualData)
local RoadBuilderCreation = require(ReplicatedStorage.RoadBuilder.RoadBuilderCreation)
local PointVector2Data = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.PointVector2Data)
local RoadConfigData = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.RoadConfigData)
local RoadBuilderAssetGetter = require(ReplicatedStorage.RoadBuilder.RoadBuilderAssetGetter)
local VisualizeCreateType = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.CreateTypeWrappers.VisualizeCreateType)
local RoadTypeEnums = require(ReplicatedStorage.RoadBuilder.RoadBuilderEnums.RoadTypeEnums)
local RoadVariantEnums = require(ReplicatedStorage.RoadBuilder.RoadBuilderEnums.RoadVariantEnums)

export type RoadPointCache = {
    roadVariant: RoadVariantEnums.RoadVariantEnums;
    destructor: () -> ();
}
export type RoadExtensionCache = {
    roadVariant: RoadVariantEnums.RoadVariantEnums;
    endRoadPointVector2Data: PointVector2Data.PointVector2Data;
    destructor: () -> ();
}

local Visualization = {}
--TODO: why do u have a remake cache on client script, is it seperate from the cache here?
VisualizerClass.inherit(Visualization)

--[[
    HIGHLIGHTS
]]

local ROAD_POINT_HIGHLIGHT_LIMIT = 30

local SIMULATED_ROAD_MODEL = Instance.new("Model")
SIMULATED_ROAD_MODEL.Parent = RoadVisualizationConfig.VISUALIZATION_ASSET_CONTAINER

local VISUALIZE_ROAD_HIGHLIGHT_ASSET = RoadBuilderAssetGetter.highlights.VisualizeRoadHighlight
local VISUALIZE_ROAD_POINT_HIGHLIGHT_ASSET = RoadBuilderAssetGetter.highlights.VisualizeRoadPointHighlight

local simulatedRoadModelHighlight = VISUALIZE_ROAD_HIGHLIGHT_ASSET:Clone()
simulatedRoadModelHighlight.Parent = RoadVisualizationConfig.VISUALIZATION_ASSET_CONTAINER
simulatedRoadModelHighlight.Adornee = SIMULATED_ROAD_MODEL

local focusHighlight = VISUALIZE_ROAD_POINT_HIGHLIGHT_ASSET:Clone()
focusHighlight.Parent = RoadVisualizationConfig.VISUALIZATION_ASSET_CONTAINER

local roadPointHighlightsCache: {Highlight} = table.create(ROAD_POINT_HIGHLIGHT_LIMIT)
for _ = 1, ROAD_POINT_HIGHLIGHT_LIMIT do
    local highlight = VISUALIZE_ROAD_POINT_HIGHLIGHT_ASSET:Clone()
    highlight.Parent = RoadVisualizationConfig.VISUALIZATION_ASSET_CONTAINER
    table.insert(roadPointHighlightsCache, highlight)
end

function Visualization.ClearVisualizedRoads(whitelistedInstances: Instance | {Instance})
    return Visualization:ClearVisualizedCache(whitelistedInstances)
end

--[[
    Attaches `roadPointHighlightsCache[1]` to `roadPoint`.
]]
function Visualization.AttachFocusHighlight(roadPoint: BasePart)
    warn("HELLO???????: ", roadPoint)
    focusHighlight.Adornee = roadPoint
    warn(focusHighlight.Adornee)
end

--[[
    Unattaches `roadPointHighlightsCache[1]` to any road point.
]]
function Visualization.UnattachFocusHighlight()
    focusHighlight.Adornee = nil
end

--[[
    Creates a (simulated) road point, returning a destructor function.

     The created road point is also indexed into `simulatedRoadCache`.
]]
function Visualization.VisualizeRoadPoint(
    roadType: RoadTypeEnums.RoadTypeEnums,
    visualizeCreateType: VisualizeCreateType.VisualizeCreateType, --TODO: support this

    originVector2Data: PointVector2Data.PointVector2Data,
    avoidCaching: boolean?
): RoadPointVisualData.RoadPointVisualData
    local originRoadOutput = RoadBuilderCreation.CreateOriginRoad(
        RoadConfigData(
            roadType,
            visualizeCreateType,
            RoadVisualizationConfig.VISUALIZATION_ASSET_CONTAINER
        ),

        originVector2Data
    )
    local originRoadPointInstance = originRoadOutput.endRoadPointInstance

    local function destructor()
		originRoadPointInstance:Destroy()
		Visualization.visualizerCache[originRoadPointInstance] = nil
    end

    if not avoidCaching then
        Visualization:CacheInstancesWithData(
            originRoadPointInstance,
            {
                roadVariant = RoadVariantEnums.RoadPoint;
                destructor = destructor;
            }
        )
    end

    return RoadPointVisualData(
        originRoadPointInstance, 
        destructor
    )
end

--[[
    Creates a (simulated) road extension, returning a destructor function.

    The created road extension is also indexed into `simulatedRoadCache`.
]]
function Visualization.VisualizeRoadExtension(
    roadType: RoadTypeEnums.RoadTypeEnums,
    visualizeCreateType: VisualizeCreateType.VisualizeCreateType,

    originVector2Data: PointVector2Data.PointVector2Data,
    goalVector2Data: PointVector2Data.PointVector2Data,
    avoidCaching: boolean?
): RoadExtensionVisualData.RoadExtensionVisualData
    local originRoadPointOutput = RoadBuilderCreation.CreateOriginRoad(
        RoadConfigData(
            roadType,
            visualizeCreateType,
            RoadVisualizationConfig.VISUALIZATION_ASSET_CONTAINER
        ),

        originVector2Data
    )
    local extensionRoadOutput = RoadBuilderCreation.CreateExtensionRoad(
        RoadConfigData(
            roadType,
            visualizeCreateType,
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
		Visualization.visualizerCache[endRoadPointInstance] = nil
    end

    if not avoidCaching then
        Visualization:CacheInstancesWithData(
            {endRoadPointInstance},
            {
                endRoadPointVector2Data = endRoadPointVector2Data;
                roadVariant = RoadVariantEnums.RoadExtension;
                destructor = destructor;
            }
        )
    end

    return RoadExtensionVisualData(
        endRoadPointInstance, 
        endRoadPointVector2Data, 
        dependentRoadInstances, 
        destructor
    )
end

export type Visualization = typeof(Visualization) & VisualizerClass.VisualizerClassPublic<RoadPointCache & RoadExtensionCache>

return Visualization:: Visualization
