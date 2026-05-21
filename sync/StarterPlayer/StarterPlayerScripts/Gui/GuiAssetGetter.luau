local StarterPlayer = game:GetService("StarterPlayer")

local PlayerUtils = require(StarterPlayer.StarterPlayerScripts.ClientUtils.PlayerUtils)
local playerGui = PlayerUtils.playerGui

local Getter = {}

Getter.BuildGui = {
	gui = playerGui.BuildGui;
	roadSelection = playerGui.BuildGui.RoadSelection;
	buildMenu = playerGui.BuildGui.BuildMenu;
	buildControlsButtons = playerGui.BuildGui.BuildControlButtons;
};

Getter.TaskbarGui = {
	gui = playerGui.TaskbarGui;
	guiFrame = playerGui.TaskbarGui.Frame;
	buildButton = playerGui.TaskbarGui.Frame.BuildButton;
};

return Getter