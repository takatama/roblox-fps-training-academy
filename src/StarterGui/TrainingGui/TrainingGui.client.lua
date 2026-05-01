local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local playerGui = player:WaitForChild("PlayerGui")
if not playerGui:FindFirstChild("TrainingGuiRuntime") then
	local gui = Instance.new("ScreenGui")
	gui.Name = "TrainingGuiRuntime"
	gui.ResetOnSpawn = false
	gui.Parent = playerGui

	local title = Instance.new("TextLabel")
	title.Name = "BootTitle"
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.Position = UDim2.fromOffset(18, 18)
	title.Size = UDim2.fromOffset(360, 40)
	title.Text = config.GameName
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 26
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = gui
end
