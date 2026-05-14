local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerScripts = player.PlayerScripts
local playerGui = player.PlayerGui
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

return {
	player = player;
	
	playerScripts = playerScripts;
	playerGui = playerGui;

	character = character;
	humanoid = humanoid;
	humanoidRootPart = humanoidRootPart;
}