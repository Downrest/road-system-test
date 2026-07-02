local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Vide = require(ReplicatedStorage.SharedPackages.Vide)

local State = {}

--// CONFIGURATION

State.DEFAULT_VALUES = {
    IsInBuildMenu = false;
    IsPromptedSelection = false;
    IsMovingSelection = {
        isMoving = false;
        overrideMovementPosition = nil;
    };
    IsHoveringExistingRoadPoint = false;
    IsVisualizing = false;

    --[[
        both of these must be true because Vide.state() runs once initially to track dependcies
    ]]
    IsValidRoadSelection = true;
    IsSelectingEndPoint = true;

    CurrentRoadType = nil;
    CurrentGoalPoint = {
        goalPoint = nil;
        referenceInstance = nil;
    };
    CurrentSelectionPoint = {
        selectionPoint = nil;
        selectionDirection = nil;
    };

    PreviousGoalPosition = nil;
}

export type IsInBuildMenu = boolean
export type IsPromptedSelection = boolean
export type IsMovingSelection = {isMoving: boolean, overrideMovementPosition: BasePart?}
export type IsHoveringExistingRoadPoint = boolean
export type IsVisualizing = boolean
export type IsValidRoadSelection = boolean
export type IsSelectingEndPoint = boolean

export type CurrentRoadType = string?
export type CurrentGoalPoint = {goalPoint: BasePart?, referenceInstance: BasePart?}
export type CurrentSelectionPoint = {selectionPoint: BasePart?, selectionDirection: Vector2}

export type PreviousGoalPosition = Vector3?

export type StateNames = 
    "IsInBuildMenu"
    | "IsPromptedSelection"
    | "IsMovingSelection" 
    | "IsHoveringExistingRoadPoint"
    | "IsVisualizing"
    | "IsValidRoadSelection"

    | "CurrentRoadType"
    | "CurrentGoalPoint"
    | "CurrentSelectionPoint"

State.IsInBuildMenu = Vide.source(State.DEFAULT_VALUES.IsInBuildMenu):: Vide.source<IsInBuildMenu>
State.IsPromptedSelection = Vide.source(State.DEFAULT_VALUES.IsPromptedSelection):: Vide.source<IsPromptedSelection>
State.IsMovingSelection = Vide.source(State.DEFAULT_VALUES.IsMovingSelection):: Vide.source<IsMovingSelection>
State.IsHoveringExistingRoadPoint = Vide.source(State.DEFAULT_VALUES.IsHoveringExistingRoadPoint):: Vide.source<IsHoveringExistingRoadPoint>
State.IsVisualizing = Vide.source(State.DEFAULT_VALUES.IsVisualizing):: Vide.source<IsVisualizing>
State.IsValidRoadSelection = Vide.source(State.DEFAULT_VALUES.IsValidRoadSelection):: Vide.source<IsValidRoadSelection>
State.IsSelectingEndPoint = Vide.source(State.DEFAULT_VALUES.IsSelectingEndPoint):: Vide.source<IsSelectingEndPoint>

State.CurrentRoadType = Vide.source(State.DEFAULT_VALUES.CurrentRoadType):: Vide.source<CurrentRoadType>
State.CurrentGoalPoint = Vide.source(State.DEFAULT_VALUES.CurrentGoalPoint):: Vide.source<CurrentGoalPoint>
State.CurrentSelectionPoint = Vide.source(State.DEFAULT_VALUES.CurrentSelectionPoint):: Vide.source<CurrentSelectionPoint>

State.PreviousGoalPosition = Vide.source(State.DEFAULT_VALUES.PreviousGoalPosition):: Vide.source<PreviousGoalPosition>

type VideDerive = (callback: () -> (any)) -> (() -> (any))
type VideEffect = (callback: () -> ()) -> ()

function State.SetMovingSelection(isMoving: boolean, overrideMovementPosition: BasePart?)
    State.IsMovingSelection({
        isMoving = isMoving;
        overrideMovementPosition = overrideMovementPosition;
    })
end

function State.SetCurrentGoalPoint(goalPoint: BasePart?)
    local current = Vide.untrack(State.CurrentGoalPoint)

    State.CurrentGoalPoint({
        goalPoint = goalPoint;
        referenceInstance = current.referenceInstance;
    })
end

function State.SetCurrentGoalReference(referenceInstance: BasePart?)
    local current = Vide.untrack(State.CurrentGoalPoint)

    State.CurrentGoalPoint({
        goalPoint = current.goalPoint;
        referenceInstance = referenceInstance;
    })
end

function State.SetCurrentSelectionPoint(selectionPoint: BasePart?)
    local current = Vide.untrack(State.CurrentSelectionPoint)

    State.CurrentSelectionPoint({
        selectionPoint = selectionPoint;
        selectionDirection = current.selectionDirection;
    })
end

function State.SetCurrentSelectionDirection(selectionDirection: Vector2?)
    local current = Vide.untrack(State.CurrentSelectionPoint)

    State.CurrentSelectionPoint({
        selectionPoint = current.selectionPoint;
        selectionDirection = selectionDirection;
    })
end

--[[
    Instantiates a stable scope via `Vide.root()` inside, exposing reactive scopes `Vide.effect()` and `Vide.derive()`. Intended to be called once only per script.
]]
function State.ScopeState(func: () -> ())
    Vide.root(function()
        -- necessary for these reactive scopes to acknowledge that theyre inside a stable scope
        func()
    end)
end

--[[
    Resets the states into their `DEFAULT_VALUES`.
]]
function State.ResetStates(...: StateNames)
    if select("#", ...) > 0 then
        for _, stateName in {...} do
            local state: Vide.source<any> = State[stateName]
            local defaultValue = State.DEFAULT_VALUES[stateName]

            if state and defaultValue then
                state(defaultValue)
            end
        end

    else
        State.IsInBuildMenu(State.DEFAULT_VALUES.IsInBuildMenu)
        State.IsPromptedSelection(State.DEFAULT_VALUES.IsPromptedSelection)
        State.IsMovingSelection(State.DEFAULT_VALUES.IsMovingSelection)
        State.IsHoveringExistingRoadPoint(State.DEFAULT_VALUES.IsHoveringExistingRoadPoint)
        State.IsVisualizing(State.DEFAULT_VALUES.IsVisualizing)
        State.IsValidRoadSelection(State.DEFAULT_VALUES.IsValidRoadSelection)
        State.IsSelectingEndPoint(State.DEFAULT_VALUES.IsSelectingEndPoint)
    
        State.CurrentRoadType(State.DEFAULT_VALUES.CurrentRoadType)
        State.CurrentGoalPoint(State.DEFAULT_VALUES.CurrentGoalPoint)
        State.CurrentSelectionPoint(State.DEFAULT_VALUES.CurrentSelectionPoint)

        State.PreviousGoalPosition(State.DEFAULT_VALUES.PreviousGoalPosition)
    end
end

--[[
    Returns a dictionary of each state (function) by the time this function was called, reducing boilerplate.
]]
function State.GetStates()
    return {
        isInBuildMenu = State.IsInBuildMenu;
		isPromptedSelection = State.IsPromptedSelection;
        isMovingSelection = State.IsMovingSelection;
        isHoveringExistingRoadPoint = State.IsHoveringExistingRoadPoint;
        isVisualizing = State.IsVisualizing;
        isValidRoadSelection = State.IsValidRoadSelection;
        isSelectingEndPoint = State.IsSelectingEndPoint;

		currentRoadType = State.CurrentRoadType;
        currentGoalPoint = State.CurrentGoalPoint;
        currentSelectionPoint = State.CurrentSelectionPoint;

        previousGoalPosition = State.PreviousGoalPosition;
    }
end

export type CapturedStates = {
    isInBuildMenu: IsInBuildMenu;
    isPromptedSelection: IsPromptedSelection;
    isMovingSelection: IsMovingSelection;
    isHoveringExistingRoadPoint: IsHoveringExistingRoadPoint;
    isVisualizing: IsVisualizing;
    isValidRoadSelection: IsValidRoadSelection;
    isSelectingEndPoint: IsSelectingEndPoint;

    currentRoadType: CurrentRoadType;
    currentGoalPoint: CurrentGoalPoint;
    currentSelectionPoint: CurrentSelectionPoint;

    previousGoalPosition: PreviousGoalPosition;
}

--[[
    Returns a dictionary of each state value by the time this function was called, reducing boilerplate. To avoid unforeseen side-effects with tracking methods like `Vide.effect()`, captured states are untracked via `Vide.untrack()`.
]]
function State.CaptureStates(): CapturedStates
    return {
        isInBuildMenu = Vide.untrack(State.IsInBuildMenu);
        isPromptedSelection = Vide.untrack(State.IsPromptedSelection);
        isMovingSelection = Vide.untrack(State.IsMovingSelection);
        isHoveringExistingRoadPoint = Vide.untrack(State.IsHoveringExistingRoadPoint);
        isVisualizing = Vide.untrack(State.IsVisualizing);
        isValidRoadSelection = Vide.untrack(State.IsValidRoadSelection);
        isSelectingEndPoint = Vide.untrack(State.IsSelectingEndPoint);

        currentRoadType = Vide.untrack(State.CurrentRoadType);
        currentGoalPoint = Vide.untrack(State.CurrentGoalPoint);
        currentSelectionPoint = Vide.untrack(State.CurrentSelectionPoint);

        previousGoalPosition = Vide.untrack(State.PreviousGoalPosition);
    }
end

return State
