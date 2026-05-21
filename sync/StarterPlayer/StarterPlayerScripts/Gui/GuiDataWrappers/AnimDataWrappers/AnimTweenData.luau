local StarterPlayer = game:GetService("StarterPlayer")

local AnimPropertiesData = require(StarterPlayer.StarterPlayerScripts.Gui.GuiDataWrappers.AnimDataWrappers.AnimPropertiesData)

export type AnimTweenData = {
	tweenInfo: TweenInfo;
	tweenProperties: AnimPropertiesData.AnimPropertiesData;
}

return function(
	tweenInfo: TweenInfo,
	tweenProperties: AnimPropertiesData.AnimPropertiesData
)
	return {
		tweenInfo = tweenInfo;
		tweenProperties = tweenProperties;
	}
end
