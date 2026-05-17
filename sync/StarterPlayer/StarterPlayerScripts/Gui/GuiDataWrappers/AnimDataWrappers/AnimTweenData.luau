local StarterPlayer = game:GetService("StarterPlayer")

local AnimDataProperties = require(StarterPlayer.StarterPlayerScripts.Gui.GuiDataWrappers.AnimDataWrappers.AnimDataProperties)

export type type = {
	tweenInfo: TweenInfo;
	tweenProperties: AnimDataProperties.type;
}

return function(
	tweenInfo: TweenInfo,
	tweenProperties: AnimDataProperties.type
)
	return {
		tweenInfo = tweenInfo;
		tweenProperties = tweenProperties;
	}
end
