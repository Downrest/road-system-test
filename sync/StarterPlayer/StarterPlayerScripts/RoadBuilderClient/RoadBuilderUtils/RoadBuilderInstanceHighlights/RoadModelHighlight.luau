local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local RoadBuilderAssetGetter = require(ReplicatedStorage.RoadBuilder.RoadBuilderAssetGetter)
local RoadVisualizationConfig = require(StarterPlayer.StarterPlayerScripts.RoadBuilderClient.RoadBuilderConfig.RoadVisualizationConfig)

local ModelHighlight = {}

local MODEL_CONTAINER = Instance.new("Model")
MODEL_CONTAINER.Parent = RoadVisualizationConfig.VISUALIZATION_ASSET_CONTAINER

local MODEL_HIGHLIGHT = RoadBuilderAssetGetter.highlights.VisualizeRoadHighlight:Clone()
MODEL_HIGHLIGHT.Parent = MODEL_CONTAINER
MODEL_HIGHLIGHT.Adornee = MODEL_CONTAINER

ModelHighlight.Container = MODEL_CONTAINER
ModelHighlight.HighlightInstance = MODEL_HIGHLIGHT

return ModelHighlight
