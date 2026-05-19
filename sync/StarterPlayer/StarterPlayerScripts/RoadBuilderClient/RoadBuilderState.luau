local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PointVector2Data = require(ReplicatedStorage.RoadBuilder.RoadBuilderDataWrappers.PointVector2Data)
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

function State.Effect(func: () -> ())
    Vide.root(function()
        Vide.effect(func)
    end)
end

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
        isInBuildMenuState = State.IsInBuildMenu;
		isPromptedSelectionState = State.IsPromptedSelection;
		currentRoadTypeState = State.CurrentRoadType;
		selectedRoadPointState = State.SelectedRoadPoint;
        selectedRoadVector2Direction = State.SelectedRoadVector2Direction;
		simulatedRoadPointState = State.SimulatedRoadPoint;
    }
end

--[[
    Returns a dictionary of each state value by the time this function was called, reducing boilerplate.
]]
function State.CaptureStates()
    return {
        isInBuildMenuState = State.IsInBuildMenu():: boolean;
		isPromptedSelectionState = State.IsPromptedSelection():: boolean;
		currentRoadTypeState = State.CurrentRoadType():: string?;
		selectedRoadPointState = State.SelectedRoadPoint():: BasePart?;
        selectedRoadVector2Direction = State.SelectedRoadVector2Direction():: Vector2?;
		simulatedRoadPointState = State.SimulatedRoadPoint():: BasePart?;
    }
end

return State
