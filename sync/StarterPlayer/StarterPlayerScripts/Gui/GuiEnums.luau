local StarterPlayer = game:GetService("StarterPlayer")

local GuiGetter = require(StarterPlayer.StarterPlayerScripts.Gui.GuiGetter)
local GuiEnums = {}

local buildGui = GuiGetter.BuildGui.gui
local taskbarGui = GuiGetter.TaskbarGui.gui

--[[
    FOCUS CATEGORIES (see GuiSignals.DefocusGui)
]]

--TODO
GuiEnums.focusLists = {
    MainInterface = {taskbarGui};
}

return GuiEnums