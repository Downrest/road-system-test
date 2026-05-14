local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.SharedUtils.Signal)

local DefocusGui = {}

--[[
	when triggered, disables
]]
DefocusGui.DefocusGui = Signal.new():: Signal.Signal<(exemptedGuis: {ScreenGui}) -> ()>
DefocusGui.FocusGui = Signal.new():: Signal.Signal<(focusedGuis: {ScreenGui}) -> ()>

--[[
	SIGNAL WRAPPER FUNCTIONS
]]

function DefocusGui.OnFocus(focusFunc: () -> ())
	return DefocusGui.FocusGui:Connect(function(focusedGuis)

	end)
end

--[[
	Wrapper for signal connection whenever a gui wants focus and everything else be unfocused. Returns a connection.

	@boilerplate
]]
function DefocusGui.OnDefocus(selfGui: ScreenGui, defocusFunc: () -> ())
	return DefocusGui.DefocusGui:Connect(function(exemptedGuis) 
		if table.find(exemptedGuis, selfGui) then
			return
		end

		defocusFunc()
	end)
end

function DefocusGui.DefocusAllGuisExcept(...: ScreenGui | {ScreenGui})
	DefocusGui.DefocusGui:Fire(...)
end

function DefocusGui.FocusGuis(...: ScreenGui | {ScreenGui})
	DefocusGui.FocusGui:Fire(...)
end

return DefocusGui
