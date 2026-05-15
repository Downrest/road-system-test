local StarterPlayer = game:GetService("StarterPlayer")

local GuiGetter = require(StarterPlayer.StarterPlayerScripts.Gui.GuiGetter)
local FocusSignals = require(StarterPlayer.StarterPlayerScripts.Gui.GuiSignals.FocusSignals)

local buildMenu = GuiGetter.BuildGui.buildMenu

FocusSignals.BuildInterface.OnFocus(buildMenu, function()
    warn("roadselection focused")
    buildMenu.Visible = true
end)

FocusSignals.BuildInterface.OnDefocus(buildMenu, function()
    warn("roadselection defocused")
    buildMenu.Visible = false
end)
