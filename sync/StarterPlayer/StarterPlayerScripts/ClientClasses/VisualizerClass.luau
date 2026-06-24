local VisualizerClass = {}
local internal = {}

type DefaultTypeCache = {[string]: any}
type CacheDestructor = () -> ()
type CacheDefault<typeCache = DefaultTypeCache> = typeCache & {
    destructor: CacheDestructor;
} 

type VisualizerCache<typeCache> = {[Instance]: CacheDefault<typeCache>}

local function ensureInstanceTable(instance: {Instance} | Instance): {Instance}
	local instanceTable = instance
	if typeof(instance) ~= "table" then
		instanceTable = {instance}
	end

	return instanceTable
end

function internal.GetInstanceVisualData<typeCache>(
	self: VisualizerClassPrivate,
	instance: Instance
): CacheDefault<typeCache>
	return self.visualizerCache[instance]
end

function internal.CacheInstancesWithData(
	self: VisualizerClassPrivate,
	instancesToIndex: {Instance} | Instance,
	data: {[string]: any}
)
	local indexTable = ensureInstanceTable(instancesToIndex)

	for _, instance in indexTable do
		self.visualizerCache[instance] = data
	end
end

function internal.ClearVisualizedCache(
	self: VisualizerClassPrivate,
	whitelistedInstances: {Instance} | Instance
)
	local visualizerCache = self.visualizerCache

	local whitelistedTable = ensureInstanceTable(whitelistedInstances)

	-- if statement to avoid unnecessary `table.find()` calls when `whitelistedTable` does not exist
	if whitelistedTable then
		for visualizationInstance, visualizationData in visualizerCache do
			if table.find(whitelistedTable, visualizationInstance) then
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

--TODO: check if colon sugar syntax works here
function VisualizerClass.inherit(self: {[any]: any})
	self.visualizerCache = {}

	self.GetInstanceVisualData = internal.GetInstanceVisualData
	self.CacheInstancesWithData = internal.CacheInstancesWithData
	self.ClearVisualizedCache = internal.ClearVisualizedCache
end

export type VisualizerClassPublic<typeCache = DefaultTypeCache> = {
	visualizerCache: VisualizerCache<typeCache>;
    GetInstanceVisualData: typeof(internal.GetInstanceVisualData);
}
export type VisualizerClassPrivate<typeCache = DefaultTypeCache> = typeof(internal) & {
	visualizerCache: VisualizerCache<typeCache>;
}

return VisualizerClass
