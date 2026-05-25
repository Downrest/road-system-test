local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local MouseUtils = require(StarterPlayer.StarterPlayerScripts.ClientUtils.MouseUtils)
local InputManager = require(StarterPlayer.StarterPlayerScripts.Inputs.InputManager)
local Janitor = require(ReplicatedStorage.SharedPackages.Janitor)
local Signal = require(ReplicatedStorage.SharedPackages.Signal)

local GuiDragUtils = {}

type DestructorFunction = () -> ()
export type DragContinueSignal = MouseUtils.MouseDeltaChangedSignal -- equivalent for now
export type DragStartedSignal = Signal.Signal
export type DragEndedSignal = Signal.Signal
export type DragObject = {
    DragContinueSignal: DragContinueSignal;
    DragStartedSignal: DragStartedSignal;
    DragEndedSignal: DragEndedSignal;
}

--[[
    When attached to a specific `guiObject`, returns a table with the following fields:
        
    * `DragContinueSignal` which further returns a "drag delta" Vector2 when fired. 
    * `
]]
function GuiDragUtils.new(guiObject: GuiButton): (DragObject, DestructorFunction)
    local init = {}

    init._isHolding = false
    init._janitor = Janitor.new()

    -- inspired by UIDragDetector, which i wouldve used but it doesnt support billboardguis in the way i need it to
    init.DragContinueSignal = Signal.new()
    init.DragStartedSignal = Signal.new()
    init.DragEndedSignal = Signal.new()

    -- button down
    init._janitor:Add(guiObject.MouseButton1Down:Connect(function()
        init._isHolding = true
        init.DragStartedSignal:Fire()
    end))

    --[[
        THESE ARE BOTH FOR BUTTON DOWN, let me explain

        1) `guiObject.MouseButton1Up` is for when the cursor is on the button gui
        2) `InputManager.UnPress` is for when the cursor is out of the button gui (because apparently
        CAS doesnt trigger `:BindAction()` calls for mouse-related input types if your mouse
        is on top of an interactable gui like a button)
    ]]
    init._janitor:Add(guiObject.MouseButton1Up:Connect(function()
        init._isHolding = false
        init.DragEndedSignal:Fire()
    end))
	init._janitor:Add(InputManager.UnPress:Connect(function()
		init._isHolding = false
        init.DragEndedSignal:Fire()
	end), "Disconnect")
    
    init._janitor:Add(MouseUtils.MouseDeltaChanged:Connect(function()
        if not init._isHolding then
            return
        end

        init.DragContinueSignal:Fire(MouseUtils.GetMouseDelta())
    end), "Disconnect")

    local function destructor()
        init._janitor:Destroy()
        init = nil
    end

    return init, destructor
end

return GuiDragUtils
