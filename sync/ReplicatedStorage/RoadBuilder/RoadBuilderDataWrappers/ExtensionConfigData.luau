export type ExtensionConfigData = {
    isEndPoint: boolean;
}

return function(
    isEndPoint: boolean
): ExtensionConfigData
    return {
        isEndPoint = isEndPoint;
    }
end
