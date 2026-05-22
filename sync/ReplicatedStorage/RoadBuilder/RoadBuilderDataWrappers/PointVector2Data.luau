local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VectorUtils = require(ReplicatedStorage.SharedUtils.VectorUtils)

export type PointVector2Data = {
	position: Vector2,
	direction: Vector2?,
	yLevel: number
}
export type PointVector2DataEnsuredDir = {
	position: Vector2,
	direction: Vector2,
	yLevel: number
}

--[[
	Creates a PointVector2Data, commonly used for systems that work with internal Vector2 grids. Automatically converts Vector3s into Vector2s.
	
	Use `yLevel` to dictate Vector3 Y level.
]]
return function(
	position: Vector3 | Vector2, 
	direction: (Vector3 | Vector2)?, 
	yLevel: number?
): PointVector2Data	
	local isPositionVector3 = (typeof(position) == "Vector3")
	local isdirectionVector3 = (typeof(direction) == "Vector3")

	return {
		position = isPositionVector3 and VectorUtils.Vector2FromVector3(position) or position;
		direction = direction 
			and (
				isdirectionVector3 
					and VectorUtils.Vector2FromVector3(direction)
					or direction
			);
		yLevel = yLevel 
			or (
				isPositionVector3 
					and position.Y
					or error(`"position" is not a Vector3, yet yLevel is nil`)
			)
	}
end