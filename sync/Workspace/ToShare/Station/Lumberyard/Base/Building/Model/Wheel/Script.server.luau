local part = script.Parent
local rotationSpeed = 2 

while task.wait() do
	part.CFrame = part.CFrame * CFrame.Angles(0, 0, math.rad(rotationSpeed))
end