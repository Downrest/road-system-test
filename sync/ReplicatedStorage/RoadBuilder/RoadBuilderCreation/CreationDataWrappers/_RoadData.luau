export type type = {
	originPosition: Vector2,
	goalPosition: Vector2,
	roadYLevel: number
}

return function(
	originPosition: Vector2, 
	goalPosition: Vector2, 
	roadYLevel: number
): type
	return {
		originPosition = originPosition,
		goalPosition = goalPosition,
		roadYLevel = roadYLevel
	}
end