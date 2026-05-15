local StarterPlayer = game:GetService("StarterPlayer")

local AnimDataUtils = require(StarterPlayer.StarterPlayerScripts.Gui.GuiAnimData.AnimDataUtils)
local GuiGetter = require(StarterPlayer.StarterPlayerScripts.Gui.GuiGetter)

local taskbarGuiFrame = GuiGetter.TaskbarGui.guiFrame
local TASKBAR_BAKED_POSITION = taskbarGuiFrame.Position

return {
    taskbarGuiFrame = AnimDataUtils.AnimData(
        {
            Visible = true;
        },
        AnimDataUtils.TweenData(
            TweenInfo.new(.5),
            {
                Position = UDim2.fromScale(
                    TASKBAR_BAKED_POSITION.X.Scale,
                    TASKBAR_BAKED_POSITION.Y.Scale
                );
            }
        ),
        AnimDataUtils.TweenData(
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