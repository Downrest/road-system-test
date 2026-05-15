local StarterPlayer = game:GetService("StarterPlayer")

local PlayerUtils = require(StarterPlayer.StarterPlayerScripts.ClientUtils.PlayerUtils)
local playerGui = PlayerUtils.playerGui

return {
    BuildGui = {
        gui = playerGui.BuildGui;
        roadSelection = playerGui.BuildGui.RoadSelection;
		buildMenu = playerGui.BuildGui.BuildMenu;
		buildControlsButtons = playerGui.BuildGui.BuildControlButtons;
    };
    TaskbarGui = {
		gui = playerGui.TaskbarGui;
		guiFrame = playerGui.TaskbarGui.Frame;
        buildButton = playerGui.TaskbarGui.Frame.BuildButton;
    };
}