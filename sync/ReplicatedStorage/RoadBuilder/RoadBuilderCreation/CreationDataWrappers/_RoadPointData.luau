export type type = {
	position: Vector2,
	roadYLevel: number
}

return function (
	position: Vector2, 
	roadYLevel: number
): type
	return {
		position = position,
		roadYLevel = roadYLevel
	}
end