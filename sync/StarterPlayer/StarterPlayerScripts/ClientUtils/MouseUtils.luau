local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")
local UserInputService = game:GetService("UserInputService")

local PlayerUtils = require(StarterPlayer.StarterPlayerScripts.ClientUtils.PlayerUtils)
local Signal = require(ReplicatedStorage.SharedPackages.Signal)
local camera = workspace.CurrentCamera

local MouseUtils = {}

--// CONFIGURATION

local MOUSE_RAY_PARAMS = RaycastParams.new()
MOUSE_RAY_PARAMS.FilterDescendantsInstances = {PlayerUtils.character}
MOUSE_RAY_PARAMS.FilterType = Enum.RaycastFilterType.Exclude
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
        mouseRay.Direction * (overrideRayDistance or DEFAULT_RAY_DISTANCE),
        MOUSE_RAY_PARAMS
    )

    return mouseCast
end

--[[
    MOUSE DELTA
]]

local previousMousePosition = UserInputService:GetMouseLocation()
local currentMouseDeltaVector2 = Vector2.zero

export type MouseDeltaChangedSignal = Signal.Signal<(deltaVector2: Vector2) -> ()>
MouseUtils.MouseDeltaChanged = Signal.new():: MouseDeltaChangedSignal

RunService.RenderStepped:Connect(function()
    local currentMousePosition = UserInputService:GetMouseLocation()
    currentMouseDeltaVector2 = (previousMousePosition - currentMousePosition)
    previousMousePosition = currentMousePosition
    
    MouseUtils.MouseDeltaChanged:Fire(currentMouseDeltaVector2.X, currentMouseDeltaVector2.Y)
end)

--[[
    Returns mouse position data in pixels.
]]
function MouseUtils.GetMouseDelta(): Vector2
    return currentMouseDeltaVector2
end

return MouseUtils
