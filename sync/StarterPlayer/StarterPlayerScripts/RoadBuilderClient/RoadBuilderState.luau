local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Vide = require(ReplicatedStorage.SharedPackages.Vide)

local State = {}

--// CONFIGURATION

local DEFAULT_VALUES = {
    IsInBuildMenu = false;
    IsPromptedSelection = false;
    CurrentRoadType = nil;
    SelectedRoadPoint = nil;
    SelectedRoadVector2Direction = nil;
    SimulatedRoadPoint = nil;
}

State.IsInBuildMenu = Vide.source(DEFAULT_VALUES.IsInBuildMenu):: Vide.source<boolean>
State.IsPromptedSelection = Vide.source(DEFAULT_VALUES.IsPromptedSelection):: Vide.source<boolean>
State.CurrentRoadType = Vide.source(DEFAULT_VALUES.CurrentRoadType):: Vide.source<string?>
State.SelectedRoadPoint = Vide.source(DEFAULT_VALUES.SelectedRoadPoint):: Vide.source<BasePart?>
State.SelectedRoadVector2Direction = Vide.source(DEFAULT_VALUES.SelectedRoadVector2Direction):: Vide.source<Vector2?>
State.SimulatedRoadPoint = Vide.source(DEFAULT_VALUES.SimulatedRoadPoint):: Vide.source<BasePart?>

type VideDerive = (callback: () -> (any)) -> (() -> (any))
type VideEffect = (callback: () -> ()) -> ()

--[[
    Instantiates a stable scope via `Vide.root()` inside, exposing reactive scopes `Vide.effect()` and `Vide.derive()`. Intended to be called once only per script.
]]
function State.ScopeState(func: (effect: VideEffect, derive: VideDerive) -> ())
    Vide.root(function()
        -- necessary for these reactive scopes to acknowledge that theyre inside a stable scope
        func(Vide.effect, Vide.derive)
    end)
end

--[[
    Resets the states into their `DEFAULT_VALUES`.
]]
function State.ResetStates()
    State.IsInBuildMenu(DEFAULT_VALUES.IsInBuildMenu)
    State.IsPromptedSelection(DEFAULT_VALUES.IsPromptedSelection)
    State.CurrentRoadType(DEFAULT_VALUES.CurrentRoadType)
    State.SelectedRoadPoint(DEFAULT_VALUES.SelectedRoadPoint)
    State.SelectedRoadVector2Direction(DEFAULT_VALUES.SelectedRoadVector2Direction)
    State.SimulatedRoadPoint(DEFAULT_VALUES.SimulatedRoadPoint)
end

--[[
    Returns a dictionary of each state (function) by the time this function was called, reducing boilerplate.
]]
function State.GetStates()
    return {
        isInBuildMenu = State.IsInBuildMenu;
		isPromptedSelection = State.IsPromptedSelection;
		currentRoadType = State.CurrentRoadType;
		selectedRoadPoint = State.SelectedRoadPoint;
        selectedRoadVector2Direction = State.SelectedRoadVector2Direction;
		simulatedRoadPoint = State.SimulatedRoadPoint;
    }
end

--[[
    Returns a dictionary of each state value by the time this function was called, reducing boilerplate.
]]
function State.CaptureStates()
    return {
        isInBuildMenu = State.IsInBuildMenu():: boolean;
		isPromptedSelection = State.IsPromptedSelection():: boolean;
		currentRoadType = State.CurrentRoadType():: string?;
		selectedRoadPoint = State.SelectedRoadPoint():: BasePart?;
        selectedRoadVector2Direction = State.SelectedRoadVector2Direction():: Vector2?;
		simulatedRoadPoint = State.SimulatedRoadPoint():: BasePart?;
    }
end

return State
