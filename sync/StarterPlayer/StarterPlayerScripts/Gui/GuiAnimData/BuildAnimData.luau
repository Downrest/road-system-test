local StarterPlayer = game:GetService("StarterPlayer")

local AnimDataUtils = require(StarterPlayer.StarterPlayerScripts.Gui.GuiAnimData.AnimDataUtils)
local GuiGetter = require(StarterPlayer.StarterPlayerScripts.Gui.GuiGetter)

local roadSelection = GuiGetter.BuildGui.roadSelection
local ROAD_SELECTION_BAKED_POSITION = roadSelection.Position

return {
	roadSelection = AnimDataUtils.AnimData(
        {
            Visible = true;
            Position = UDim2.fromScale(
                ROAD_SELECTION_BAKED_POSITION.X.Scale,
                1.25
            );
        },
        AnimDataUtils.TweenData(
            TweenInfo.new(.5),
            {
                Position = UDim2.fromScale(
                    ROAD_SELECTION_BAKED_POSITION.X.Scale,
                    ROAD_SELECTION_BAKED_POSITION.Y.Scale
                )
            }
        ),
        AnimDataUtils.TweenData(
            TweenInfo.new(.5),
            {
                Position = UDim2.fromScale(
                    ROAD_SELECTION_BAKED_POSITION.X.Scale,
                    1.25
                )
            }
        )
    );
}