local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.SharedUtils.Signal)

local GuiSignals = {}

--[[
	when triggered, disables
]]
GuiSignals.DefocusGui = Signal.new():: Signal.Signal<(exemptedGuis: {ScreenGui}) -> ()>
GuiSignals.FocusGui = Signal.new():: Signal.Signal<(focusedGuis: {ScreenGui}) -> ()>

--[[
	SIGNAL WRAPPER FUNCTIONS
]]

function GuiSignals.OnFocus(focusFunc: () -> ())
	return GuiSignals.FocusGui:Connect(function(focusedGuis)

	end)
end

--[[
	Wrapper for signal connection whenever a gui wants focus and everything else be unfocused. Returns a connection.

	@boilerplate
]]
function GuiSignals.OnDefocus(selfGui: ScreenGui, defocusFunc: () -> ())
	return GuiSignals.DefocusGui:Connect(function(exemptedGuis) 
		if table.find(exemptedGuis, selfGui) then
			return
		end

		defocusFunc()
	end)
end

function GuiSignals.DefocusAllGuisExcept(...: ScreenGui | {ScreenGui})
	GuiSignals.DefocusGui:Fire(...)
end

function GuiSignals.FocusGuis(...: ScreenGui | {ScreenGui})
	GuiSignals.FocusGui:Fire(...)
end

return GuiSignals