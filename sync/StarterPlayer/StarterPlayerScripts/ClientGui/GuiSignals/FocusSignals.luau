local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.SharedUtils.Signal)
local TableUtils = require(ReplicatedStorage.SharedUtils.TableUtils)

local FocusSignals = {}

--[[
	when triggered, disables
]]
FocusSignals.DefocusGui = Signal.new():: Signal.Signal<(exemptedGuis: {ScreenGui}) -> ()>
FocusSignals.FocusGui = Signal.new():: Signal.Signal<(focusedGuis: {ScreenGui}) -> ()>

--[[
	SIGNAL WRAPPER FUNCTIONS
]]

function FocusSignals.OnFocus(selfGui: ScreenGui, focusFunc: () -> ())
	return FocusSignals.FocusGui:Connect(function(focusedGuis)
		-- return if selfGui isnt one of the guis in focus request
		if not table.find(focusedGuis, selfGui) then
			return
		end

		focusFunc(focusedGuis)
	end)
end

function FocusSignals.OnDefocus(selfGui: ScreenGui, defocusFunc: () -> ())
	return FocusSignals.DefocusGui:Connect(function(exemptedGuis) 
		-- return if selfGui is in exemptedGuis (unaffected by defocus request)
		if table.find(exemptedGuis, selfGui) then
			return
		end

		defocusFunc(exemptedGuis)
	end)
end

function FocusSignals.DefocusAllGuisExcept(...: ScreenGui | {ScreenGui})
	FocusSignals.DefocusGui:Fire(TableUtils.Merge(...))
end

function FocusSignals.FocusGuis(...: ScreenGui | {ScreenGui})
	FocusSignals.FocusGui:Fire(TableUtils.Merge(...))
end

return FocusSignals
