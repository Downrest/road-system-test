local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RoadInstanceTagEnums = require(ReplicatedStorage.RoadBuilder.RoadBuilderEnums.RoadInstanceTagEnums)

local SelectionValidator = {}

function SelectionValidator.VerifyRoadPoint(instance: BasePart): boolean
    return instance and instance:HasTag(RoadInstanceTagEnums.RoadPoint) or false
end

return SelectionValidator
