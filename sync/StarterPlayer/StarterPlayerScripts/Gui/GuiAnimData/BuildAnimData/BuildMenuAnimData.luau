local StarterPlayer = game:GetService("StarterPlayer")

local AnimData = require(StarterPlayer.StarterPlayerScripts.Gui.GuiDataWrappers.AnimDataWrappers.AnimData)
local AnimTweenData = require(StarterPlayer.StarterPlayerScripts.Gui.GuiDataWrappers.AnimDataWrappers.AnimTweenData)
local GuiAssetGetter = require(StarterPlayer.StarterPlayerScripts.Gui.GuiUtils.GuiAssetGetter)

local buildMenu = GuiAssetGetter.BuildGui.buildMenu
local BUILD_MENU_BAKED_POSITION = buildMenu.Position

return AnimData(
    {
        Visible = true;
        Position = UDim2.fromScale(
            -.25,
            BUILD_MENU_BAKED_POSITION.Y.Scale
        );
    },
    AnimTweenData(
        TweenInfo.new(.5),
        {
            Position = UDim2.fromScale(
                BUILD_MENU_BAKED_POSITION.X.Scale,
                BUILD_MENU_BAKED_POSITION.Y.Scale
            )
        }
    ),
    AnimTweenData(
        TweenInfo.new(.5),
        {
            Position = UDim2.fromScale(
                -.25,
                BUILD_MENU_BAKED_POSITION.Y.Scale
            )
        }
    )
);