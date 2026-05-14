local StarterPlayer = game:GetService("StarterPlayer")

local GuiGetter = require(StarterPlayer.StarterPlayerScripts.ClientGui.GuiGetter)
local GuiEnums = {}

local buildGui = GuiGetter.BuildGui
local taskbarGui = GuiGetter.TaskbarGui

--[[
    FOCUS CATEGORIES (see GuiSignals.DefocusGui)
]]

GuiEnums.focusLists = {
    MainInterface = {taskbarGui};
}

return GuiEnums