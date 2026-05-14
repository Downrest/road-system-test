local Visualizer = {}

Visualizer.TaggedVisualizers = {}:: {
    [any]: {BasePart}
}

---// INTERNAL

local function createTagArray(tag: any): {BasePart}
    local tagArray = Visualizer.TaggedVisualizers[tag]

    if not tagArray then
        Visualizer.TaggedVisualizers[tag] = {}
        tagArray = Visualizer.TaggedVisualizers[tag]
    end

    return tagArray
end

local function destroyPartsInArray(array: {BasePart})
    for _, part in array do
        part:Destroy()
    end
end

local function createPart(position: Vector3): BasePart
    local part = Instance.new("Part")
    part.Position = position
    part.Size = Vector3.one
    part.CanCollide = false
	part.CanQuery = false
	part.Anchored = true
    part.Parent = workspace

    return part
end

---// PUBLIC

export type VisualizerOutput = BasePart | {BasePart} 

function Visualizer.ClearVisualizers(tag: any?)
    local indexedTagArray = Visualizer.TaggedVisualizers[tag]

    -- if tag found
    if indexedTagArray then
        destroyPartsInArray(indexedTagArray)

    -- otherwise, clear all existing tags
    else
        for _, tagArray: {[any]: BasePart} in Visualizer.TaggedVisualizers do
            destroyPartsInArray(tagArray)
        end
    end
end

function Visualizer.VisualizePosition(tag: any?, ...: Vector3): VisualizerOutput
    local positions = {...}
    local visualizers = {}

   local tagArray = createTagArray(tag)

    for _, position in positions do
       local part = createPart(position)

        table.insert(tagArray, part)
        table.insert(visualizers, part)
    end

    return #visualizers <= 1 and visualizers[1] or visualizers
end

return Visualizer
