local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TableUtils = require(ReplicatedStorage.SharedUtils.TableUtils)

local PropertiesUtils = {}

local function property(object: Instance, propertiesTable: {[string]: any})
    -- choosing not to pcall for, performance reasons
    for propertyName, propertyValue in propertiesTable do
        object[propertyName] = propertyValue
    end
end

function PropertiesUtils.ApplyProperties(object: Instance | {Instance}, propertiesTable: {[string]: any})
    assert(object, "No `object` supplied for properties?")
    assert(propertiesTable, "No `propertiesTable` supplied for properties?")

    local objectTable = object
    if typeof(object) ~= "table" then
        objectTable = {objectTable}
    end

    for _, traversedObject: Instance in objectTable do
        property(traversedObject, propertiesTable)
    end
end

return PropertiesUtils
