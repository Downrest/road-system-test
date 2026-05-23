local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")

local MouseUtils = require(StarterPlayer.StarterPlayerScripts.ClientUtils.MouseUtils)
local Janitor = require(ReplicatedStorage.SharedPackages.Janitor)
local Signal = require(ReplicatedStorage.SharedPackages.Signal)

local GuiDragUtils = {}

export type IsDraggingSignal = MouseUtils.MouseDeltaChangedSignal

function GuiDragUtils.new(guiObject: GuiButton)
    local init = {}

    init._isHolding = false
    init._janitor = Janitor.new()

    init.IsDragging = Signal.new():: IsDraggingSignal

    init._janitor:Add(guiObject.MouseButton1Down:Connect(function()
        warn("pressed")
        init._isHolding = true
    end))
    init._janitor:Add(guiObject.MouseButton1Up:Connect(function()
        init._isHolding = false
    end))
    init._janitor:Add(RunService.RenderStepped:Connect(function()
        if not init._isHolding then
            return
        end

        init.IsDragging:Fire(MouseUtils.GetMouseDelta())
    end))

    local function destructor()
        init._janitor:Destroy()
        init = nil
    end

    return init, destructor
end

return GuiDragUtils
