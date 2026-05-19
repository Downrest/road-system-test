export type type = {
	roadType: string, 
	createType: string,
	roadParent: Instance
}

return function(
    roadType: string, 
	createType: string,
	roadParent: Instance
): type
    assert(roadType, "No roadType: string")
	assert(createType, "No createType: string")
	assert(roadParent, "No roadParent: Instance")

    return {
        roadType = roadType,
        createType = createType,
        roadParent = roadParent
    }
end
