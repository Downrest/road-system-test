local createEventsFolder = script.CreationEvents
local createRoadRequestEvent = createEventsFolder.CreateRoadRequest

local cacheEventsFolder = script.CacheEvents
local replicateRoadData = cacheEventsFolder.ReplicateRoadData

return {
	CreateRoadRequest = createRoadRequestEvent;

	ReplicateRoadData = replicateRoadData;
}