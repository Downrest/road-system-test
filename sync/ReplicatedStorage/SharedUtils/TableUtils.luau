local TableUtils = {}

function TableUtils.EnsureTable<T>(any: T | {T}): {T}
	if typeof(any) ~= "table" then
		any = {any}
	end

	return any
end

--[[
	Merges `...` into a single array `{...}` in descending order (the first parameters are in the first slot of the array).

	`...` can either be an arrays, non-tables, or both.
]]
function TableUtils.MergeArray<T>(...: {T} | T): {T}
	local parameters = {...}
	local merged = {}

	for _, value in parameters do
		if typeof(value) == "table" then
			table.move(value, 1, #value, #merged+1, merged)
		else
			table.insert(merged, value)
		end
	end

	return merged
end

return TableUtils