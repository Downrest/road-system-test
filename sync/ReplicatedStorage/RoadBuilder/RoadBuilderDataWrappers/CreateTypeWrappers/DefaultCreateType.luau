local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CreateTypeEnums = require(ReplicatedStorage.RoadBuilder.RoadBuilderEnums.CreateTypeEnums)

export type DefaultCreateType = {
    tag: CreateTypeEnums.DefaultType;
}

return {
    tag = CreateTypeEnums.Default;
}:: DefaultCreateType
