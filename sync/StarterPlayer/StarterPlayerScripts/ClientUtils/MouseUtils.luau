local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Signal = require(ReplicatedStorage.SharedPackages.Signal)
local camera = workspace.CurrentCamera

local MouseUtils = {}

--[[
    RAYCASTING
]]

local DEFAULT_RAY_DISTANCE = 1000

--[[
    Returns a Ray pointed towards mouse location, for actual raycasting see `MouseUtils.GetMouseCast()`.
]]
function MouseUtils.GetMouseRay(): Ray?
    local mouseLocation = UserInputService:GetMouseLocation()
    local mouseRay = camera:ViewportPointToRay(mouseLocation.X, mouseLocation.Y)

    return mouseRay
end

--[[
    Returns a RaycastResult pointed towards mouse location.
]]
function MouseUtils.GetMouseCast(overrideRayDistance: number?, overrideMouseRay: Ray?): RaycastResult?
    local mouseRay = overrideMouseRay or MouseUtils.GetMouseRay()
    local mouseCast = workspace:Raycast(
        mouseRay.Origin, 
        mouseRay.Direction * (overrideRayDistance or DEFAULT_RAY_DISTANCE)
    )

    return mouseCast
end

--[[
    MOUSE DELTA
]]

local previousMousePosition = UserInputService:GetMouseLocation()
local currentMouseDelta = 0

export type MouseDeltaChangedSignal = Signal.Signal<(delta: number) -> ()>
MouseUtils.MouseDeltaChanged = Signal.new():: MouseDeltaChangedSignal

RunService.RenderStepped:Connect(function()
    local currentMousePosition = UserInputService:GetMouseLocation()
    currentMouseDelta = (previousMousePosition - currentMousePosition).Magnitude
    previousMousePosition = currentMousePosition
    
    MouseUtils.MouseDeltaChanged:Fire()
end)

--[[
    Returns mouse position data in pixels.
]]
function MouseUtils.GetMouseDelta()
    return currentMouseDelta
end

return MouseUtils
