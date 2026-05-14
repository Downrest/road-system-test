local TableUtils = {}

function TableUtils.IsTable(value: any): boolean
	return (typeof(value) == "table")
end

function TableUtils.Merge<T>(...: T): {T}
	local parameters = {...}
	local merged = {}

	for _, value in parameters do
		if TableUtils.IsTable(value) then
			
		end
	end

	return merged
end

return TableUtils