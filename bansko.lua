--potition
local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local root = character:WaitForChild("HumanoidRootPart")

local pos = root.Position
local coords = "X: "..math.floor(pos.X).." Y: "..math.floor(pos.Y).." Z: "..math.floor(pos.Z)

-- Copy to clipboard (executor feature)
if setclipboard then
    setclipboard(coords)
end

-- Show Roblox notification
game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "Position Copied";
    Text = coords;
    Duration = 10;
})
