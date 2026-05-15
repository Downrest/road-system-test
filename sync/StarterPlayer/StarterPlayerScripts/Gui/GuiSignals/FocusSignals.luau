local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.SharedUtils.Signal)
local TableUtils = require(ReplicatedStorage.SharedUtils.TableUtils)

local FocusSignals = {}

type DefocusGuiSignal = Signal.Signal<(exemptedGuis: {GuiObject}) -> ()>
type FocusGuiSignal = Signal.Signal<(focusedGuis: {GuiObject}) -> ()>

local function onFocus(_signal: FocusGuiSignal, targettedGui: GuiObject, focusFunc: () -> ())
	return _signal:Connect(function(focusedGuis)
		-- return if targettedGui isnt one of the guis in focus request
		if not table.find(focusedGuis, targettedGui) then
			return
		end

		focusFunc(focusedGuis)
	end)
end

local function onDefocus(_signal: DefocusGuiSignal, targettedGui: GuiObject, defocusFunc: () -> ())
	return _signal:Connect(function(exemptedGuis) 
		-- return if targettedGui is in exemptedGuis (unaffected by defocus request)
		if table.find(exemptedGuis, targettedGui) then
			return
		end

		defocusFunc(exemptedGuis)
	end)
end

local function defocusAllGuisExcept(_signal: DefocusGuiSignal, ...: GuiObject | {GuiObject})
	local exemptedGuis = TableUtils.Merge(...)

	_signal:Fire(exemptedGuis)
end

local function focusGuis(_focusSignal: FocusGuiSignal, _defocusSignal: DefocusGuiSignal, ...: GuiObject | {GuiObject})
	local focusedGuis = TableUtils.Merge(...) 
	assert(#focusedGuis > 0, "FocusGuis() yet no guis passed in parameters")

	_focusSignal:Fire(focusedGuis)

	return {
		DefocusAllGuisExcept = function(...)
			defocusAllGuisExcept(_defocusSignal, TableUtils.Merge(focusedGuis, ...))
		end
	}
end

type FocusSignalListener = (targettedGui: GuiObject, func: () -> ()) -> ();

type TargettedGuisParameter = GuiObject | {GuiObject}
type DefocusAllGuisExcept = (...TargettedGuisParameter) -> ();
type FocusGuis = (...TargettedGuisParameter) -> ({
	DefocusAllGuisExcept: DefocusAllGuisExcept -- chain method
});

type FocusCategory = {
	-- raw signals
	FocusGuiSignal: FocusGuiSignal;
	DefocusGuiSignal: DefocusGuiSignal;

	-- signal listeners/wrappers
	OnFocus: FocusSignalListener;
	OnDefocus: FocusSignalListener;

	-- methods
	FocusGuis: FocusGuis; -- returns a chain method for DefocusAllGuisExcept
	DefocusAllGuisExcept: DefocusAllGuisExcept;
}

-- factory for FocusCategory
local function newFocusCategory(): FocusCategory
	local focusCategory = {}

	focusCategory.FocusGuiSignal = Signal.new();
	focusCategory.DefocusGuiSignal = Signal.new();

	--[[
		Listens to any fired calls to FocusGuiSignal, if `targettedGui` is being focused, trigger `focusFunc()`
	]]
	focusCategory.OnFocus = function(targettedGui, focusFunc)
		onFocus(focusCategory.FocusGuiSignal, targettedGui, focusFunc)
	end;
	--[[
		Listens to any fired calls to DefocusGuiSignal, if `targettedGui` is being defocused, trigger `defocusFunc()`
	]]
	focusCategory.OnDefocus = function(targettedGui, defocusFunc)
		onDefocus(focusCategory.DefocusGuiSignal, targettedGui, defocusFunc)
	end;

	--[[
		Fires FocusGuiSignal with `...`, triggering `OnFocus` methods attached to the specified `...`
	]]
	focusCategory.FocusGuis = function(...)
		return focusGuis(focusCategory.FocusGuiSignal, focusCategory.DefocusGuiSignal, ...)
	end;
	focusCategory.DefocusAllGuisExcept = function(...)
		defocusAllGuisExcept(focusCategory.DefocusGuiSignal, ...)
	end;
	
	return focusCategory
end

--// PUBLIC

FocusSignals.MainInterface = newFocusCategory()

FocusSignals.BuildInterface = newFocusCategory()


return FocusSignals
