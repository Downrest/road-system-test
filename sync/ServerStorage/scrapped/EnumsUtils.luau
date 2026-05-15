local EnumUtils = {}

type Enum = {[string]: string}

--[[
	A simple wrapper for enum-like dictionaries where indices and keys are equivalent strings.
	
	```luau
	-- example
	local enum = EnumUtils.new("Red", "Green", "Bluee")
	local enum2 = {
		Red = "Red";
		Green = "Green";
		Blue = "Blue";
	}
	
	warn(enum == enum2) -- true
	```
]]
local x


function EnumUtils.StringKeyValue(...)
	local values = {...}
	local enum = {}
	
	for _, value in values do
		assert(typeof(value) == "string", "Enum value isn't a string!")
		enum[value] = value
	end
	
	return enum
end

return EnumUtils
