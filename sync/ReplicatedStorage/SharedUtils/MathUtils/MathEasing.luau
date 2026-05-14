--[[
	built on https://easings.net/#

	not a complete port, just what i need (for now)
]]

local Easing = {}

--[[
	Returns a tuple of n amount of easing points spaced 1/n apart. The easing function is inputted via  `easeFunc`.
]]
function Easing.GetEasingPointsTuple(n: number, easeFunc: (number) -> (number)): number
	local easingPointsTuple = {}

	for i = 0, 1, (1/n) do
		table.insert(easingPointsTuple, easeFunc(i))
	end

	return table.unpack(easingPointsTuple)
end

--[[
	QUART
]]

--[[
	https://easings.net/#easeInQuart
]]
function Easing.EaseInQuart(x: number): number
	return x^4
end

--[[
	CIRC
]]

--[[
	https://easings.net/#easeInCirc
]]
function Easing.EaseInCirc(x: number): number
	return 1 - math.sqrt(1 - math.pow(x, 2))
end

--[[
	EXPONENTIAL
]]

--[[
	https://easings.net/#easeInExpo
]]
function Easing.EaseInExpo(x: number): number
	return (x == 0) and 0 or math.pow(2, 10 * x - 10)
end

return Easing
