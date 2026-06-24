local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local VisualizerClass = require(StarterPlayer.StarterPlayerScripts.ClientClasses.VisualizerClass)
local GuiDragUtils = require(StarterPlayer.StarterPlayerScripts.ClientUtils.GuiDragUtils)
local RoadInterfaceConfig = require(StarterPlayer.StarterPlayerScripts.RoadBuilderClient.RoadBuilderConfig.RoadInterfaceConfig)
local RoadBuilderAssetGetter = require(ReplicatedStorage.RoadBuilder.RoadBuilderAssetGetter)
local Signal = require(ReplicatedStorage.SharedPackages.Signal)

type DestructorFunction = () -> ()
type SelectTriggeredSignal = Signal.Signal
type UndoTriggeredSignal = Signal.Signal
type VerticalDragContinueSignal = Signal.Signal
type VerticalDragStartedSignal = Signal.Signal
type VerticalDragEndedSignal = Signal.Signal
type ResetStartedSignal = Signal.Signal
type ResetEndedSignal = Signal.Signal

type SelectionPromptGui = {
    gui: BillboardGui;

    confirmationFrame: {
        frame: Frame;
        selectButton: ImageButton;
        undoButton: ImageButton;
    };

    movementFrame: {
        frame: Frame;
        verticalHandle: ImageButton;
    };

    resetFrame: {
        frame: Frame;
        resetButton: ImageButton;
    }
}
type SelectionPromptSignals = {
    selectTriggered: SelectTriggeredSignal;
    undoTriggered: UndoTriggeredSignal;

    verticalDragContinue: VerticalDragContinueSignal;
    verticalDragStarted: VerticalDragStartedSignal;
    verticalDragEnded: VerticalDragEndedSignal;

    resetStarted: ResetStartedSignal;
    resetEnded: ResetEndedSignal;
}

type SelectionPromptData = {
    signals: SelectionPromptSignals;
    destructor: () -> ();
}

local SelectionPrompt = {}
VisualizerClass.inherit(SelectionPrompt)

local SELECTION_GUI_ASSET = RoadBuilderAssetGetter.guis.SelectionGui

function SelectionPrompt.ClearSelectionPrompts(whitelistedInstances: Instance | {Instance})
    SelectionPrompt:ClearVisualizedCache(whitelistedInstances)
end

local function selectionPromptGui(
    gui: BillboardGui,

    confirmationFrame: Frame,
    confirmationSelectButton: ImageButton,
    confirmationUndoButton: ImageButton,

    movementFrame: Frame,
    movementVerticalHandle: ImageButton,

    resetFrame: Frame,
    resetButton: ImageButton
): SelectionPromptGui
    return {
        gui = gui;
        confirmationFrame = {
            frame = confirmationFrame;
            selectButton = confirmationSelectButton;
            undoButton = confirmationUndoButton;
        };
        movementFrame = {
            frame = movementFrame;
            verticalHandle = movementVerticalHandle;
        };
        resetFrame = {
            frame = resetFrame;
            resetButton = resetButton;
        }
    }
end

local function selectionPromptSignals(
    selectTriggeredSignal: Signal.Signal,
    undoTriggeredSignal: Signal.Signal,
    verticalDragContinueSignal: Signal.Signal,
    verticalDragStartedSignal: Signal.Signal,
    verticalDragEndedSignal: Signal.Signal,
    resetStartedSignal: Signal.Signal,
    resetEndedSignal: Signal.Signal
): SelectionPromptSignals
    return {
        selectTriggered = selectTriggeredSignal;
        undoTriggered = undoTriggeredSignal;

        verticalDragContinue = verticalDragContinueSignal;
        verticalDragStarted = verticalDragStartedSignal;
        verticalDragEnded = verticalDragEndedSignal;

        resetStarted = resetStartedSignal;
        resetEnded = resetEndedSignal;
    }
end

--[[
    Creates a selection prompt parented to `adornee` parameter, returning 1) select-triggered signal, 2) undo-triggered signal, and 3) destructor function.

    The created selection prompt is also indexed into `selectionPromptCache`.
]]
function SelectionPrompt.CreateSelectionPrompt(adornee: BasePart?): (
    SelectionPromptGui, SelectionPromptSignals, DestructorFunction
)
    
	local selectionGuiClone = SELECTION_GUI_ASSET:Clone()
    selectionGuiClone.Parent = RoadInterfaceConfig.INTERFACE_PARENT
    if adornee then
        selectionGuiClone.Adornee = adornee
    end

    --[[
        FRAMES
    ]]

    local confirmationFrame = selectionGuiClone.Confirmation
    local selectButton = confirmationFrame.Select
    local undoButton = confirmationFrame.Undo

    local movementFrame = selectionGuiClone.Movement
    local verticalHandle = movementFrame.VerticalHandle
    local verticalGuiDrag, verticalGuiDragDestructor = GuiDragUtils.new(verticalHandle)

    local resetFrame = selectionGuiClone.Reset
    local resetButton = resetFrame.ResetButton

    local selectionGui = selectionPromptGui(
        selectionGuiClone,
        confirmationFrame,
        selectButton,
        undoButton,
        movementFrame,
        verticalHandle,
        resetFrame,
        resetButton
    )

    --[[
        SIGNALS
    ]]
    
    local selectionSignals = selectionPromptSignals(
        Signal.new(),
        Signal.new(),
        verticalGuiDrag.DragContinueSignal,
        verticalGuiDrag.DragStartedSignal,
        verticalGuiDrag.DragEndedSignal,
        Signal.new(),
        Signal.new()
    )

	local hasResetted = false
	resetButton.MouseButton1Down:Connect(function()
        if not hasResetted then
            selectionSignals.resetStarted:Fire()
        else
            selectionSignals.resetEnded:Fire()
        end
        hasResetted = not hasResetted
    end)
    selectButton.MouseButton1Down:Connect(function()
        selectionSignals.selectTriggered:Fire()
    end)
    undoButton.MouseButton1Down:Connect(function()
        selectionSignals.undoTriggered:Fire()
    end)

    -- destructor method
    local function destructor()
        selectionGuiClone:Destroy()
        for _, signal in selectionSignals do
            signal:Destroy()
        end
        verticalGuiDragDestructor()
		SelectionPrompt.visualizerCache[selectionGuiClone] = nil
    end

    SelectionPrompt:CacheInstancesWithData(
        selectionGuiClone,
        {
            signals = selectionSignals;
            destructor = destructor;
        }
    )

    return 
        selectionGui, 
        selectionSignals,
        destructor
end

export type SelectionPrompt = typeof(SelectionPrompt) & VisualizerClass.VisualizerClassPublic<SelectionPromptData>

return SelectionPrompt:: SelectionPrompt
