local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local VisualizerClass = require(StarterPlayer.StarterPlayerScripts.ClientClasses.VisualizerClass)
local RoadVisualizationConfig = require(StarterPlayer.StarterPlayerScripts.RoadBuilderClient.RoadBuilderConfig.RoadVisualizationConfig)
local RoadExtensionVisualData = require(StarterPlayer.StarterPlayerScripts.RoadBuilderClient.RoadBuilderDataWrappers.VisualizationWrappers.RoadExtensionVisualData)
local RoadPointVisualData = require(StarterPlayer.StarterPlayerScripts.RoadBuilderClient.RoadBuilderDataWrappers.VisualizationWrappers.RoadPointVisualData)
local PointHighlightEnum = require(StarterPlayer.StarterPlayerScripts.RoadBuilderClient.RoadBuilderEnums.PointHighlightEnum)
local RoadModelHighlight = require(StarterPlayer.StarterPlayerScripts.RoadBuilderClient.RoadBuilderUtils.RoadBuilderInstanceHighlights.RoadModelHighlight)
local RoadPointHighlight = require(StarterPlayer.StarterPlayerScripts.RoadBuilderClient.RoadBuilderUtils.RoadBuilderInstanceHighlights.RoadPointHighlight)
local RoadBuilderCreation = require(ReplicatedStorage.RoadBuilder.RoadBuilderCreation)
local PointVector2Data = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.PointVector2Data)
local RoadConfigData = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.RoadConfigData)
local VisualizeCreateType = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.CreatePropertyWrappers.VisualizeCreateType)
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
VisualizerClass.inherit(Visualization)


function Visualization.ClearVisualizedRoads(whitelistedInstances: Instance | {Instance})
    return Visualization:ClearVisualizedCache(whitelistedInstances)
end

--[[
    Creates a (simulated) road point, returning a destructor function.

     The created road point is also indexed into `simulatedRoadCache`.
]]
function Visualization.VisualizeRoadPoint(
    roadType: RoadTypeEnums.RoadTypeEnums,
    visualizeCreateType: VisualizeCreateType.VisualizeCreateType,

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

    -- if shouldHighlight then
    --     RoadPointHighlight.HighlightRoadPoints(originRoadPointInstance, PointHighlightEnum.EndPointHighlight)
    -- end

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
            VisualizeCreateType(
                visualizeCreateType.visualizedProperties.road,
                visualizeCreateType.visualizedProperties.roadPoint,
                RoadVisualizationConfig.VISUALIZATION_ASSET_CONTAINER
            )
        ),

        originVector2Data
    )
    local extensionRoadOutput = RoadBuilderCreation.CreateExtensionRoad(
        RoadConfigData(
            roadType,
            VisualizeCreateType(
                visualizeCreateType.visualizedProperties.road,
                visualizeCreateType.visualizedProperties.roadPoint,
                RoadModelHighlight.Container
            )
        ),
        
        originVector2Data,
        goalVector2Data
    )
    local endRoadPointInstance = extensionRoadOutput.endRoadPointInstance
    local endRoadPointVector2Data = extensionRoadOutput.endRoadPointVector2Data

    local dependentRoadInstances = extensionRoadOutput.dependentRoadInstances
    table.insert(dependentRoadInstances.roadPoints, originRoadPointOutput.endRoadPointInstance) -- extra line to insert originRoadPoint

    -- local allRoadPoints = table.move(dependentRoadInstances.roadPoints, 1, #dependentRoadInstances.roadPoints, 2, {endRoadPointInstance})
    -- if shouldHighlight then
    --     RoadPointHighlight.HighlightRoadPoints(endRoadPointInstance, PointHighlightEnum.EndPointHighlight)
    --     RoadPointHighlight.HighlightRoadPoints(dependentRoadInstances.roadPoints, PointHighlightEnum.DependentPointHighlight)
    -- end

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
