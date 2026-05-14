local General = {}

--[[
    Returns a result from the pythagorean theorem between b, c
]]
function General.Pythagorean(b: number, c: number): number
	return math.sqrt(b^2 - c^2)
end

--[[
    Returns an angle (from dot product) between two Vector2s

    https://en.wikipedia.org/wiki/Dot_product#Properties 
]]
function General.DotAngleBetween(direction1: Vector2, direction2: Vector2): number
	return math.deg(
		math.acos(
			direction1.Unit:Dot(direction2.Unit) 
				/ (
					math.sqrt(direction1.X^2 + direction1.Y^2)
					* math.sqrt(direction2.X^2 + direction2.Y^2)
				)
		)
	)
end

--[[
    Returns a factorial of n
]]
function General.Factorial(n: number): number  
	local value = 1	
	for i = 2, n do -- automatically doesnt run if n is 0 or 1
		value *= i
	end
	return value
end

--[[
    Returns a binomial coefficient of n, k

    https://en.wikipedia.org/wiki/Binomial_coefficient
]]
function General.BinomialCoefficient(n: number, k: number): number
	return General.Factorial(n) / (General.Factorial(k) * General.Factorial(n - k))
end

--[[
	Returns a bezier curve with nth amount of points
	
	https://en.wikipedia.org/wiki/B%C3%A9zier_curve (explicit definition)

	```luau
	-- example
	BezierCurve.NthBezierCurve(.5, 1, 2) -- returns 1.5
	BezierCurve.NthBezierCurve(.5, 1, 2, 3) -- returns 2
	```
]]

return General
