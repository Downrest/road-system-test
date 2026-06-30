local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local VisualizerClass = require(StarterPlayer.StarterPlayerScripts.ClientClasses.VisualizerClass)
local RoadVisualizationConfig = require(StarterPlayer.StarterPlayerScripts.RoadBuilderClient.RoadBuilderConfig.RoadVisualizationConfig)
local RoadExtensionVisualData = require(StarterPlayer.StarterPlayerScripts.RoadBuilderClient.RoadBuilderDataWrappers.VisualizationWrappers.RoadExtensionVisualData)
local RoadPointVisualData = require(StarterPlayer.StarterPlayerScripts.RoadBuilderClient.RoadBuilderDataWrappers.VisualizationWrappers.RoadPointVisualData)
local RoadModelHighlight = require(StarterPlayer.StarterPlayerScripts.RoadBuilderClient.RoadBuilderUtils.RoadBuilderInstanceHighlights.RoadModelHighlight)
local RoadBuilderCreation = require(ReplicatedStorage.RoadBuilder.RoadBuilderCreation)
local PointVector2Data = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.PointVector2Data)
local RoadConfigData = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.RoadConfigData)
local VisualizeCreateType = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.CreatePropertyWrappers.VisualizeCreateType)
local CreateVariantEnums = require(ReplicatedStorage.RoadBuilder.RoadBuilderEnums.CreateVariantEnums)
local RoadTypeEnums = require(ReplicatedStorage.RoadBuilder.RoadBuilderEnums.RoadTypeEnums)
local RoadVariantEnums = require(ReplicatedStorage.RoadBuilder.RoadBuilderEnums.RoadVariantEnums)
local PropertiesUtils = require(ReplicatedStorage.SharedUtils.PropertiesUtils)

export type RoadPointCache = {
    createVariant: CreateVariantEnums.CreateVariantEnums;
    destructor: () -> ();
}
export type RoadExtensionCache = {
    createVariant: CreateVariantEnums.CreateVariantEnums;
    endRoadPointVector2Data: PointVector2Data.PointVector2Data;
    destructor: () -> ();
}

local Visualization = {}
VisualizerClass.inherit(Visualization)


function Visualization.ClearVisualizedRoads(whitelistedInstances: Instance | {Instance})
    return Visualization:ClearVisualizedCache(whitelistedInstances)
end

function Visualization.ApplyVisualizeCreateTypeProperties(
    roadInstance: BasePart,
    createVariant: RoadVariantEnums.RoadVariantEnums,
    visualizeCreateType: VisualizeCreateType.VisualizeCreateType
)
    PropertiesUtils.ApplyProperties(
        roadInstance,
        createVariant == RoadVariantEnums.RoadPoint
            and visualizeCreateType.visualizedProperties.roadPoint
            or visualizeCreateType.visualizedProperties.road
    )
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
    visualizeCreateType.parent = RoadVisualizationConfig.VISUALIZATION_ASSET_CONTAINER

    local originRoadOutput = RoadBuilderCreation.CreateOriginRoadPoint(
        RoadConfigData(
            roadType,
            visualizeCreateType
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
                createVariant = CreateVariantEnums.RoadPoint;
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
    visualizeCreateType.parent = RoadVisualizationConfig.VISUALIZATION_ASSET_CONTAINER

    local originRoadPointOutput = RoadBuilderCreation.CreateOriginRoadPoint(
        RoadConfigData(
            roadType,
            VisualizeCreateType(
                visualizeCreateType.visualizedProperties.road,
                visualizeCreateType.visualizedProperties.roadPoint
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
                createVariant = CreateVariantEnums.RoadExtension;
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
