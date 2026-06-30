local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TableUtils = require(ReplicatedStorage.SharedUtils.TableUtils)

local PropertiesUtils = {}

local function property(object: Instance, propertiesTable: {[string]: any})
    -- choosing not to pcall for, performance reasons
    for propertyName, propertyValue in propertiesTable do
        object[propertyName] = propertyValue
    end
end

function PropertiesUtils.ApplyProperties(objects: Instance | {Instance}, propertiesTable: {[string]: any})
    assert(objects, "No `objects` supplied for properties?")
    assert(propertiesTable, "No `propertiesTable` supplied for properties?")

    objects = TableUtils.EnsureTable(objects)

    for _, traversedObject: Instance in objects do
        property(traversedObject, propertiesTable)
    end
end

return PropertiesUtils
