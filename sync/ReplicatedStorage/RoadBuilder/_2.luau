local Events = {}

local createRoadRequestEvent = script.CreateRoadRequest

local cacheEventsFolder = script.CacheEvents
local requestRoadData = cacheEventsFolder.RequestRoadData

return {
	CreateRoadRequest = createRoadRequestEvent;
	
	RequestRoadData = requestRoadData;
}