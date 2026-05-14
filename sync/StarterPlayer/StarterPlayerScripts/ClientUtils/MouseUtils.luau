local UserInputService = game:GetService("UserInputService")
local camera = workspace.CurrentCamera

local MouseService = {}

function MouseService.GetMouseRay(): Ray?
    local mouseLocation = UserInputService:GetMouseLocation()
    local mouseRay = camera:ViewportPointToRay(mouseLocation.X, mouseLocation.Y)

    return mouseRay
end

function MouseService.GetMouseCast(overrideMouseRay: Ray?): RaycastResult?
    local mouseRay = overrideMouseRay or MouseService.GetMouseRay()
    local mouseCast = workspace:Raycast(mouseRay.Origin, mouseRay.Direction * 1000)

    return mouseCast
end

return MouseService
