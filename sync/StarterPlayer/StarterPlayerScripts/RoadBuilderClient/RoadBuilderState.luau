local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CharmState = require(ReplicatedStorage.SharedUtils.CharmState)

local State = {}

State.IsInBuildMenu = CharmState.atom(false):: CharmState.Atom<boolean>
State.IsPromptedSelection = CharmState.atom(false):: CharmState.Atom<boolean>

State.CurrentRoadType = CharmState.atom(nil):: CharmState.Atom<string?>
State.SelectedRoadPoint = CharmState.atom(nil):: CharmState.Atom<BasePart?>
State.SimulatedRoadPoint = CharmState.atom(nil):: CharmState.Atom<BasePart?>

return State
