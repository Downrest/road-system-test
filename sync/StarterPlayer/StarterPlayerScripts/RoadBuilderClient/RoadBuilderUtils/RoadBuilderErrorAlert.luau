local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local RoadBuilderAssetGetter = require(ReplicatedStorage.RoadBuilder.RoadBuilderAssetGetter)
local VisualizerClass = require(StarterPlayer.StarterPlayerScripts.ClientClasses.VisualizerClass)
local RoadVisualizationConfig = require(StarterPlayer.StarterPlayerScripts.RoadBuilderClient.RoadBuilderConfig.RoadVisualizationConfig)

type Destructor = () -> ()
type ErrorAlertData = {
    destructor: () -> ();
}

local ErrorAlert = {}
VisualizerClass.inherit(ErrorAlert)

local ERROR_ALERT_TEMPLATE = RoadBuilderAssetGetter.guis.ErrorAlert

function ErrorAlert.ClearErrorAlerts(whitelistedInstances: Instance | {Instance})
    ErrorAlert:ClearVisualizedCache(whitelistedInstances)
end

function ErrorAlert.CreateErrorAlert(adornee: Instance): (typeof(ERROR_ALERT_TEMPLATE), Destructor)
    local errorAlertGui = ERROR_ALERT_TEMPLATE:Clone()
    errorAlertGui.Parent = RoadVisualizationConfig.VISUALIZATION_ASSET_CONTAINER
    errorAlertGui.Adornee = adornee

    -- destructor method
    local function destructor()
        errorAlertGui:Destroy()
        ErrorAlert.visualizerCache[errorAlertGui] = nil
    end

    ErrorAlert:CacheInstancesWithData(
        errorAlertGui,
        {
            destructor = destructor;
        }
    )

    return 
        errorAlertGui, 
        destructor
end

export type ErrorAlert = typeof(ErrorAlert) & VisualizerClass.VisualizerClassPublic<ErrorAlertData>

return ErrorAlert:: ErrorAlert
