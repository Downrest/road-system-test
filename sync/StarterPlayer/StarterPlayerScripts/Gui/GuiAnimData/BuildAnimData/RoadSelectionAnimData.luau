local StarterPlayer = game:GetService("StarterPlayer")

local AnimData = require(StarterPlayer.StarterPlayerScripts.Gui.GuiDataWrappers.AnimDataWrappers.AnimData)
local AnimTweenData = require(StarterPlayer.StarterPlayerScripts.Gui.GuiDataWrappers.AnimDataWrappers.AnimTweenData)
local GuiAssetGetter = require(StarterPlayer.StarterPlayerScripts.Gui.GuiUtils.GuiAssetGetter)

local roadSelection = GuiAssetGetter.BuildGui.roadSelection
local ROAD_SELECTION_BAKED_POSITION = roadSelection.Position

return AnimData(
    {
        Visible = true;
        Position = UDim2.fromScale(
            ROAD_SELECTION_BAKED_POSITION.X.Scale,
            1.25
        );
    },
    AnimTweenData(
        TweenInfo.new(.5),
        {
            Position = UDim2.fromScale(
                ROAD_SELECTION_BAKED_POSITION.X.Scale,
                ROAD_SELECTION_BAKED_POSITION.Y.Scale
            )
        }
    ),
    AnimTweenData(
        TweenInfo.new(.5),
        {
            Position = UDim2.fromScale(
                ROAD_SELECTION_BAKED_POSITION.X.Scale,
                1.25
            )
        }
    )
);