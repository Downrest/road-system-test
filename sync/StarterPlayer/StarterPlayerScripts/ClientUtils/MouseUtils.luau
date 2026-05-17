local UserInputService = game:GetService("UserInputService")
local camera = workspace.CurrentCamera

local MouseService = {}

local DEFAULT_RAY_DISTANCE = 1000

function MouseService.GetMouseRay(): Ray?
    local mouseLocation = UserInputService:GetMouseLocation()
    local mouseRay = camera:ViewportPointToRay(mouseLocation.X, mouseLocation.Y)

    return mouseRay
end

function MouseService.GetMouseCast(overrideRayDistance: number?, overrideMouseRay: Ray?): RaycastResult?
    local mouseRay = overrideMouseRay or MouseService.GetMouseRay()
    local mouseCast = workspace:Raycast(
        mouseRay.Origin, 
        mouseRay.Direction * (overrideRayDistance or DEFAULT_RAY_DISTANCE)
    )

    return mouseCast
end

return MouseService
