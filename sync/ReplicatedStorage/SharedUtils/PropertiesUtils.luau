local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TableUtils = require(ReplicatedStorage.SharedUtils.TableUtils)
local PropertiesUtils = {}

function PropertiesUtils.ApplyProperties(object: Instance, propertiesTable: {[string]: any})
    for propertyName, propertyValue in propertiesTable do
        pcall(function()
            object[propertyName] = propertyValue
        end)
    end
end

return PropertiesUtils
