local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RoadBuilderEnums = require(ReplicatedStorage.RoadBuilder.RoadBuilderEnums)
local Data = {}

--// CONFIGURATION

type RoadDataList = {[BasePart]: RoadBuilderEnums.RoadData}

Data.RoadDataList = {}:: RoadDataList

--// PUBLIC

function Data.GetRoad(instance: BasePart): RoadBuilderEnums.RoadData
    return Data.RoadDataList[instance]
end

function Data.AddRoad(
    instance: BasePart,
    roadType: string
)
    assert(instance, "Attempted to add road to RoadData, no instance given")
    assert(RoadBuilderEnums.RoadDataPresets[roadType], "Road type does not exist")

    Data.RoadDataList[instance] = RoadBuilderEnums.RoadDataPresets[roadType]
end

return Data
