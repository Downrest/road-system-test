local Vector = {}

function Vector.Vector2FromVector3(vector3: Vector3): Vector2
	return Vector2.new(vector3.X, vector3.Z)
end

function Vector.Vector3FromVector2AndY(vector2: Vector2, y: number): Vector3
	return Vector3.new(vector2.X, y, vector2.Y)
end

return Vector
