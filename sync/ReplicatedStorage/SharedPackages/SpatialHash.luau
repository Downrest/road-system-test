local SpatialHash = {}
local internal = {}
internal.__index = internal

local function toHashPosition(self: SpatialHash, position: Vector3): Vector3
    local cellSize = self._cellSize

    return Vector3.new(
        math.floor(position.X / cellSize),
        math.floor(position.Y / cellSize),
        math.floor(position.Z / cellSize)
    )
end

-- cleans up hash if its empty
local function cleanupHash(self: SpatialHash, hashPosition: Vector3)
    local hash = self:GetHash(hashPosition)
    if not hash then
        return
    end

    if #hash == 0 then
        self._hash[hashPosition] = nil
    end
end

function SpatialHash.new<hash>(cellSize: number): SpatialHash<hash>
    local self = {}
    self._cellSize = cellSize
    self._hash = {}

    return setmetatable(self, internal)
end

--[[
    Pushes a value into the hash of position `popPosition`, has two modes of pushing:

    * With `pushIndex`, merely sets index on hash table to `pushValue`
    * Without `pushIndex`, uses `table.insert(..., pushValue)` to insert `pushValue`
]]
function internal.PushValue(self: SpatialHash, pushPosition: Vector3, pushIndex: any?, pushValue: any)
    local hashTable = self._hash
    local hashPosition = toHashPosition(self, pushPosition)

    local hash = hashTable[hashPosition]

    if not hash then
        hashTable[hashPosition] = {}
        hash = hashTable[hashPosition]
    end
    if pushIndex then
        hash[pushIndex] = pushValue
    else
        table.insert(hash, pushValue)
    end
end

--[[
    Pops a value into the hash of position `popPosition`, has two modes of popping:

    * With `pushIndex`, merely sets index on hash table to nil
    * Without `pushIndex`, uses `table.find(..., popValue)` to find numerical index and then runs `table.remove(..., popValueIndex)`
]]
function internal.PopValue(self: SpatialHash, popPosition: Vector3, pushIndex: any?, popValue: any?)
    warn("POP")
    local hashTable = self._hash
    local hashPosition = toHashPosition(self, popPosition)
    local hash = hashTable[hashPosition]
    if not hash then
        return
    end

    if pushIndex then
        hash[pushIndex] = nil
    else
        local popValueIndex = table.find(hash, popValue)
        if not popValueIndex then
            return
        end

        table.remove(hash, popValueIndex)
    end

    -- just incase
    cleanupHash(self, hashPosition)
end

--[[
    Returns hash of position `hashPosition`
]]
function internal.GetHash(self: SpatialHash, getPosition: Vector3): {any}?
    local hashTable = self._hash
    local hashPosition = toHashPosition(self, getPosition)
    
    return hashTable[hashPosition]
end

export type SpatialHash<hash = any> = typeof(internal) & {
    _cellSize: number;
    _hash: {[Vector3]: hash}
}

return SpatialHash
