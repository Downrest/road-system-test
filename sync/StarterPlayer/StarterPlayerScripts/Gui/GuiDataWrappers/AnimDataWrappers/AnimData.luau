local StarterPlayer = game:GetService("StarterPlayer")

local AnimTweenData = require(StarterPlayer.StarterPlayerScripts.Gui.GuiDataWrappers.AnimDataWrappers.AnimTweenData)
local AnimDataProperties = require(StarterPlayer.StarterPlayerScripts.Gui.GuiDataWrappers.AnimDataWrappers.AnimDataProperties)

export type type = {
	initProperties: AnimDataProperties.type;

	focusedTweenData: AnimTweenData.type;
	defocusedTweenData: AnimTweenData.type;
}

return function(
	initProperties: AnimDataProperties.type,
	focusedTweenData: AnimTweenData.type,
	defocusedTweenData: AnimTweenData.type
): type
	return {
		initProperties = initProperties;
		focusedTweenData = focusedTweenData;
		defocusedTweenData = defocusedTweenData;
	}
end