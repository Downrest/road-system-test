local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MathGeneral = require(ReplicatedStorage.SharedUtils.MathUtils.MathGeneral)

local Curves = {}

--[[
	Returns a bezier curve with nth amount of points
	
	https://en.wikipedia.org/wiki/B%C3%A9zier_curve (explicit definition)

	```luau
	-- example
	BezierCurve.NthBezierCurve(.5, 1, 2) -- returns 1.5
	BezierCurve.NthBezierCurve(.5, 1, 2, 3) -- returns 2
	```
]]
function Curves.NthBezierCurve(t: number, ...)
	local points = {...}

	--[[
		you need to subtract #points by 1 because
			1: the summation in the formula uses "i" to increment in the range of [0, n]
			2: the first point is considered the origin / "0"th point, 
			so its disregarded from n (collection of control points for bezier curve)

		so we shift n backwards by 1 
		to fit it with the formula
	]]
	local n = #points - 1 

	local value = 0

	for i = 0, n do
		value += (MathGeneral.BinomialCoefficient(n, i) * (1-t)^(n-i) * t^i * points[i+1])
	end

	return value
end

return Curves
