local VisualizerClass = {}
local internal = {}
internal.__index = internal

type CacheDestructor = () -> ()

type DefaultTypeCache = {[string]: any}
export type CacheDefault<typeCache = DefaultTypeCache> = typeCache & {
    destructor: CacheDestructor;
} 

function VisualizerClass.inherit(self: {[any]: any})
    self.visualizerCache = {}

    return setmetatable(self, internal)
end

function internal.GetInstanceVisualData<typeCache>(
    self: VisualizerClassPrivate,
    instance: Instance
): CacheDefault<typeCache>
    return self.visualizerCache[instance]
end

function internal.CacheInstancesWithData(
    self: VisualizerClassPrivate,
    instancesToIndex: {Instance},
    data: {[string]: any}
)
    for _, instance in instancesToIndex do
        self.visualizerCache[instance] = data
    end
end

function internal.ClearVisualizedCache(
    self: VisualizerClassPrivate,
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

export type VisualizerClassPublic<typeCache = any> = CacheDefault<typeCache> & {
    GetInstanceVisualData: typeof(internal.GetInstanceVisualData);
}

export type VisualizerClassPrivate<typeCache = any> = CacheDefault<typeCache> & typeof(VisualizerClass)

return VisualizerClass
