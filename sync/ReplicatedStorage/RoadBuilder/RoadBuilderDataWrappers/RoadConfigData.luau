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
    assert(roadType, "No createType: string")
    assert(roadType, "No roadParent: Instance")

    return {
        roadType = roadType,
        createType = createType,
        roadParent = roadParent
    }
end
