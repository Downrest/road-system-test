local VisualizerClass = {}
local internal = {}
internal.__index = internal

export type CacheDestructor = () -> ()
export type Cache = {
    destructor: CacheDestructor;
    [string]: any;
}

function VisualizerClass.new<cacheType>(): VisualizerClass<cacheType>
    local self = {}
    self.visualizerCache = {}

    return setmetatable(self, internal)
end

function internal.CacheInstancesWithData(
    self: VisualizerClass,
    instancesToIndex: {Instance},
    data: {[string]: any}
)
    for _, instance in instancesToIndex do
        self.visualizerCache[instance] = data
    end
end

function internal.ClearVisualizedCache(
    self: VisualizerClass,
    whitelistedInstances: {Instance}
)
    local visualizerCache = self.visualizerCache

    -- if statement to avoid unnecessary `table.find()` calls when `whitelistedInstances` does not exist
    if whitelistedInstances then
        for visualizationInstance, visualizationData in visualizerCache do
            if table.find(whitelistedInstances, visualizationInstance) then
                continue
            end
    
            visualizationData.destructor()
        end
    else
        for _, visualizationData in visualizerCache do
            visualizationData.destructor()
        end
    end
end

export type VisualizerClass<typeCache = any> = typeof(internal) & {
    visualizerCache: {[Instance]: Cache & typeCache};
}

return VisualizerClass
