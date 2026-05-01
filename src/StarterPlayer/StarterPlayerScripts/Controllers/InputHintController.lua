local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InputHintController = {}

local player = Players.LocalPlayer
local i18n = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Localization"))

local function getOrCreateTrainingGui()
	local playerGui = player:WaitForChild("PlayerGui")
	local gui = playerGui:FindFirstChild("TrainingGuiRuntime")
	if gui then
		return gui
	end

	gui = Instance.new("ScreenGui")
	gui.Name = "TrainingGuiRuntime"
	gui.IgnoreGuiInset = false
	gui.ResetOnSpawn = false
	gui.Parent = playerGui
	return gui
end

function InputHintController.Init()
	local gui = getOrCreateTrainingGui()
	if gui:FindFirstChild("InputHints") then
		return
	end

	local hints = Instance.new("Frame")
	hints.Name = "InputHints"
	hints.AnchorPoint = Vector2.new(0.5, 1)
	hints.BackgroundTransparency = 0.25
	hints.BackgroundColor3 = Color3.fromRGB(22, 24, 30)
	hints.BorderSizePixel = 0
	hints.Position = UDim2.new(0.5, 0, 1, -22)
	hints.Size = UDim2.fromOffset(560, 46)
	hints.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = hints

	local label = Instance.new("TextLabel")
	label.Name = "HintText"
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamMedium
	label.Text = i18n.t("ui.inputHints")
	label.TextColor3 = Color3.fromRGB(240, 244, 248)
	label.TextSize = 18
	label.TextWrapped = true
	label.Size = UDim2.fromScale(1, 1)
	label.Parent = hints
end

return InputHintController
