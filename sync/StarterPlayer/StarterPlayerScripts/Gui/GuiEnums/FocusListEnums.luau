local StarterPlayer = game:GetService("StarterPlayer")

local GuiAssetGetter = require(StarterPlayer.StarterPlayerScripts.Gui.GuiUtils.GuiAssetGetter)

local buildGui = GuiAssetGetter.BuildGui.gui
local taskbarGui = GuiAssetGetter.TaskbarGui.gui

return {
	MainInterface = {taskbarGui};
}