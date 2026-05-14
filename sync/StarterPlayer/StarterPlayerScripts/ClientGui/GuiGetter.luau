local StarterPlayer = game:GetService("StarterPlayer")

local PlayerUtils = require(StarterPlayer.StarterPlayerScripts.ClientUtils.PlayerUtils)
local playerGui = PlayerUtils.playerGui

return {
    BuildGui = playerGui.BuildGui;
    TaskbarGui = playerGui.TaskbarGui;
}