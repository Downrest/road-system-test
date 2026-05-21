local StarterPlayer = game:GetService("StarterPlayer")

local AnimData = require(StarterPlayer.StarterPlayerScripts.Gui.GuiDataWrappers.AnimDataWrappers.AnimData)
local AnimTweenData = require(StarterPlayer.StarterPlayerScripts.Gui.GuiDataWrappers.AnimDataWrappers.AnimTweenData)
local GuiAssetGetter = require(StarterPlayer.StarterPlayerScripts.Gui.GuiUtils.GuiAssetGetter)

local buildControlButtons = GuiAssetGetter.BuildGui.buildControlsButtons
local BUILD_CONTROL_BUTTONS_BAKED_POSITION = buildControlButtons.Position

return AnimData(
    {
        Visible = true;
        Position = UDim2.fromScale(
            BUILD_CONTROL_BUTTONS_BAKED_POSITION.X.Scale,
            1.25
        );
    },
    AnimTweenData(
        TweenInfo.new(.5),
        {
            Position = UDim2.fromScale(
                BUILD_CONTROL_BUTTONS_BAKED_POSITION.X.Scale,
                BUILD_CONTROL_BUTTONS_BAKED_POSITION.Y.Scale
            )
        }
    ),
    AnimTweenData(
        TweenInfo.new(.5),
        {
            Position = UDim2.fromScale(
                BUILD_CONTROL_BUTTONS_BAKED_POSITION.X.Scale,
                1.25
            )
        }
    )
);