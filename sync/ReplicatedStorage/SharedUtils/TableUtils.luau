local TableUtils = {}

--[[
	Returns a guaranteed table of `any`, whether it be a value or a table of values.
]]
function TableUtils.EnsureTable<T>(any: T | {T}): {T}
	if typeof(any) ~= "table" then
		any = {any}
	end

	return any
end

--[[
	Insert all values of `inserting` into `source`.
]]
function TableUtils.InsertValues<T>(source: {T}, inserting: T | {T})
	inserting = TableUtils.EnsureTable(inserting)

	for _, insert in inserting do
		table.insert(source, insert)
	end
end

--[[
	Returns values of a given source table, no guaranteed order (for dictionaries).
]]
function TableUtils.GetValues<T>(source: {T}): {T}
	local values = {}

	for _, value in source do
		table.insert(values, value)
	end

	return values
end

--[[
	Returns keys of a given source table, no guaranteed order (for dictionaries).
]]
function TableUtils.GetKeys<T>(source: {[T]: any}): {T}
	local keys = {}

	for key in source do
		table.insert(keys, key)
	end

	return keys
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