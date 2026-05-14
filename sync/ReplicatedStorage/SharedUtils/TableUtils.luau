local TableUtils = {}

--[[
	Returns a boolean depending on whether `value` is a table.
]]
function TableUtils.IsTable(value: {any}): boolean
	return (typeof(value) == "table")
end

--[[
	Merges `...` into a single array `{...}` in descending order (the first parameters are in the first slot of the array).

	`...` can either be an arrays, non-arrays, or both.
]]
function TableUtils.Merge(...: {any} | any): {any}
	local parameters = {...}
	local merged = {}

	for _, value in parameters do
		if TableUtils.IsTable(value) then
			table.move(value, 1, #value, #merged+1, merged)
		else
			table.insert(merged, value)
		end
	end

	return merged
end

return TableUtils