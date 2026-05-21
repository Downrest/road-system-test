local StarterPlayer = game:GetService("StarterPlayer")

local AnimPropertiesData = require(StarterPlayer.StarterPlayerScripts.Gui.GuiDataWrappers.AnimDataWrappers.AnimPropertiesData)
local AnimTweenData = require(StarterPlayer.StarterPlayerScripts.Gui.GuiDataWrappers.AnimDataWrappers.AnimTweenData)


export type AnimData = {
	initProperties: AnimPropertiesData.AnimPropertiesData;

	focusedTweenData: AnimTweenData.AnimTweenData;
	defocusedTweenData: AnimTweenData.AnimTweenData;
}

return function(
	initProperties: AnimPropertiesData.AnimPropertiesData,
	focusedTweenData: AnimTweenData.AnimTweenData,
	defocusedTweenData: AnimTweenData.AnimTweenData
): AnimData
	return {
		initProperties = initProperties;
		focusedTweenData = focusedTweenData;
		defocusedTweenData = defocusedTweenData;
	}
end