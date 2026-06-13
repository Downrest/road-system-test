local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Vide = require(ReplicatedStorage.SharedPackages.Vide)
local context = require(ReplicatedStorage.SharedPackages.Vide.context)

local State = {}

--// CONFIGURATION

State.DEFAULT_VALUES = {
    IsInBuildMenu = false;
    IsPromptedSelection = false;
    IsMovingSelection = {isMoving = false, isCustomPosition = false};
    IsHoveringExistingRoadPoint = false;
    IsVisualizing = false;

    CurrentRoadType = nil;
    CurrentGoalPoint = {
        goalPoint = nil;
        referenceInstance = nil;
    };
    CurrentSelectionPoint = {
        selectionPoint = nil;
        selectionDirection = nil;
    };
}

export type IsInBuildMenu = boolean
export type IsPromptedSelection = boolean
export type IsMovingSelection = {isMoving: boolean, isCustomPosition: boolean}
export type IsHoveringExistingRoadPoint = boolean
export type IsVisualizing = boolean

export type CurrentRoadType = string?
export type CurrentGoalPoint = {goalPoint: BasePart?, referenceInstance: BasePart?}
export type CurrentSelectionPoint = {selectionPoint: BasePart?, selectionDirection: Vector2}

export type StateNames = 
    "IsInBuildMenu"
    | "IsPromptedSelection"
    | "IsMovingSelection" 
    | "IsHoveringExistingRoadPoint"
    | "IsVisualizing"

    | "CurrentRoadType"
    | "CurrentGoalPoint"
    | "CurrentSelectionPoint"

State.IsInBuildMenu = Vide.source(State.DEFAULT_VALUES.IsInBuildMenu):: Vide.source<IsInBuildMenu>
State.IsPromptedSelection = Vide.source(State.DEFAULT_VALUES.IsPromptedSelection):: Vide.source<IsPromptedSelection>
State.IsMovingSelection = Vide.source(State.DEFAULT_VALUES.IsMovingSelection):: Vide.source<IsMovingSelection>
State.IsHoveringExistingRoadPoint = Vide.source(State.DEFAULT_VALUES.IsHoveringExistingRoadPoint):: Vide.source<IsHoveringExistingRoadPoint>
State.IsVisualizing = Vide.source(State.DEFAULT_VALUES.IsVisualizing):: Vide.source<IsVisualizing>

State.CurrentRoadType = Vide.source(State.DEFAULT_VALUES.CurrentRoadType):: Vide.source<CurrentRoadType>
State.CurrentGoalPoint = Vide.source(State.DEFAULT_VALUES.CurrentGoalPoint):: Vide.source<CurrentGoalPoint>
State.CurrentSelectionPoint = Vide.source(State.DEFAULT_VALUES.CurrentSelectionPoint):: Vide.source<CurrentSelectionPoint>

type VideDerive = (callback: () -> (any)) -> (() -> (any))
type VideEffect = (callback: () -> ()) -> ()

function State.SetMovingSelection(isMoving: boolean, isCustomPosition: boolean)
    State.IsMovingSelection({
        isMoving = isMoving;
        isCustomPosition = isCustomPosition;
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
-- function State.SetCurrentSelectionPoint(selectionPoint: BasePart?, selectionDirection: Vector2?)
--     State.CurrentSelectionPoint({
--         selectionPoint = selectionPoint;
--         selectionDirection = selectionDirection;
--     })
-- end

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
    
        State.CurrentRoadType(State.DEFAULT_VALUES.CurrentRoadType)
        State.CurrentGoalPoint(State.DEFAULT_VALUES.CurrentGoalPoint)
        State.CurrentSelectionPoint(State.DEFAULT_VALUES.CurrentSelectionPoint)
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

		currentRoadType = State.CurrentRoadType;
        currentGoalPoint = State.CurrentGoalPoint;
        currentSelectionPoint = State.CurrentSelectionPoint;
    }
end

export type CapturedStates = {
    isInBuildMenu: IsInBuildMenu;
    isPromptedSelection: IsPromptedSelection;
    isMovingSelection: IsMovingSelection;
    isHoveringExistingRoadPoint: IsHoveringExistingRoadPoint;
    isVisualizing: IsVisualizing;

    currentRoadType: CurrentRoadType;
    currentGoalPoint: CurrentGoalPoint;
    currentSelectionPoint: CurrentSelectionPoint;
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

        currentRoadType = Vide.untrack(State.CurrentRoadType);
        currentGoalPoint = Vide.untrack(State.CurrentGoalPoint);
        currentSelectionPoint = Vide.untrack(State.CurrentSelectionPoint);
    }
end

return State
