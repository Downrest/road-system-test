local StarterPlayer = game:GetService("StarterPlayer")

local AnimData = require(StarterPlayer.StarterPlayerScripts.Gui.GuiDataWrappers.AnimDataWrappers.AnimData)
local AnimTweenData = require(StarterPlayer.StarterPlayerScripts.Gui.GuiDataWrappers.AnimDataWrappers.AnimTweenData)
local GuiAssetGetter = require(StarterPlayer.StarterPlayerScripts.Gui.GuiUtils.GuiAssetGetter)

local taskbarGuiFrame = GuiAssetGetter.TaskbarGui.guiFrame
local TASKBAR_BAKED_POSITION = taskbarGuiFrame.Position

return {
    taskbarGuiFrame = AnimData(
        {
            Visible = true;
            Position = UDim2.fromScale(
                TASKBAR_BAKED_POSITION.X.Scale,
                TASKBAR_BAKED_POSITION.Y.Scale
            );
        },
        AnimTweenData(
            TweenInfo.new(.5),
            {
                Position = UDim2.fromScale(
                    TASKBAR_BAKED_POSITION.X.Scale,
                    TASKBAR_BAKED_POSITION.Y.Scale
                );
            }
        ),
        AnimTweenData(
            TweenInfo.new(.5),
            {
                Position = UDim2.fromScale(
                    TASKBAR_BAKED_POSITION.X.Scale,
                    1.25
                );
            }
        )
    );
}