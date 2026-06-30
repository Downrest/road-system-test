local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local RoadVisualizationConfig = require(StarterPlayer.StarterPlayerScripts.RoadBuilderClient.RoadBuilderConfig.RoadVisualizationConfig)
local PointHighlightEnums = require(StarterPlayer.StarterPlayerScripts.RoadBuilderClient.RoadBuilderEnums.PointHighlightEnums)
local RoadBuilderAssetGetter = require(ReplicatedStorage.RoadBuilder.RoadBuilderAssetGetter)
local PropertiesUtils = require(ReplicatedStorage.SharedUtils.PropertiesUtils)
local TableUtils = require(ReplicatedStorage.SharedUtils.TableUtils)

local PointHighlight = {}

type HightlightData = {
    highlightInstance: Highlight;
    highlightEnum: PointHighlightEnums.PointHighlightEnums;
}

local ROAD_POINT_HIGHLIGHT = RoadBuilderAssetGetter.highlights.VisualizeRoadPointHighlight
local HIGHLIGHT_ENUM_TO_COLORS = {
    [PointHighlightEnums.EndPointHighlight] = RoadVisualizationConfig.HIGHLIGHT_ROAD_POINT_COLORS.endPoint;
    [PointHighlightEnums.DependentPointHighlight] = RoadVisualizationConfig.HIGHLIGHT_ROAD_POINT_COLORS.dependentPoint;
}
local DEFAULT_HIGHLIGHT_ENUM = PointHighlightEnums.DependentPointHighlight

local function highlightData(
    highlightInstance: Highlight,
    highlightEnum: PointHighlightEnums.PointHighlightEnums
): HightlightData
    return {
        highlightInstance = highlightInstance;
        highlightEnum = highlightEnum;
    }
end

PointHighlight.HighlightCache = table.create(RoadVisualizationConfig.HIGHLIGHT_ROAD_POINT_LIMIT):: {HightlightData}
for _ = 1, RoadVisualizationConfig.HIGHLIGHT_ROAD_POINT_LIMIT do
    local highlight = ROAD_POINT_HIGHLIGHT:Clone()
    highlight.Parent = RoadVisualizationConfig.VISUALIZATION_ASSET_CONTAINER
    PropertiesUtils.ApplyProperties(
        highlight, 
        HIGHLIGHT_ENUM_TO_COLORS[DEFAULT_HIGHLIGHT_ENUM]
    )

    table.insert(
        PointHighlight.HighlightCache, 
        highlightData(
            highlight,
            DEFAULT_HIGHLIGHT_ENUM
        )
    )
end

PointHighlight.TrackedRoadPoints = table.create(RoadVisualizationConfig.HIGHLIGHT_ROAD_POINT_LIMIT):: {BasePart}

local function applyHighlightEnumColor(
    highlight: Highlight,
    highlightEnum: PointHighlightEnums.PointHighlightEnums
)
    local colorProperties = HIGHLIGHT_ENUM_TO_COLORS[highlightEnum]
    assert(colorProperties, "Failed to apply highlight enum color!")

    PropertiesUtils.ApplyProperties(
        highlight,
        colorProperties
    )
end

function PointHighlight.ResetHighlightTracking()
    PointHighlight.TrackedRoadPoints = {}
end

function PointHighlight.HighlightRoadPoints(
    roadPoints: BasePart | {BasePart}, 
    highlightEnum: PointHighlightEnums.PointHighlightEnums
)
    assert(roadPoints, "`roadPoints` required for highlighting!")
    assert(roadPoints, "`highlightEnum` required for highlighting!")

	roadPoints = TableUtils.EnsureTable(roadPoints)

    local colorProperties = HIGHLIGHT_ENUM_TO_COLORS[highlightEnum]
    assert(colorProperties, "`highlightEnum` not matching any actual highlight color!")

    for _, roadPoint in roadPoints do
        local trackIndex = #PointHighlight.TrackedRoadPoints + 1
        local highlight = PointHighlight.HighlightCache[trackIndex]
        if not highlight then
            break
        end

        -- this just avoids unnecessary highlight property changes
        -- if highlight.highlightEnum ~= highlightEnum then
        --     applyHighlightEnumColor(highlight.highlightInstance, highlightEnum)
        --     highlight.highlightEnum = highlightEnum
        -- end
        applyHighlightEnumColor(highlight.highlightInstance, highlightEnum)

        highlight.highlightInstance.Adornee = roadPoint
        table.insert(PointHighlight.TrackedRoadPoints, roadPoint)
    end
end

return PointHighlight
