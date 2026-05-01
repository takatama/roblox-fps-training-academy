local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RewardClientController = {}

local player = Players.LocalPlayer
local config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local i18n = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Localization"))

local progressRemote = ReplicatedStorage
	:WaitForChild("Remotes")
	:WaitForChild(config.RemoteFolderName)
	:WaitForChild("ProgressEvent")

local statsLabel = nil

local function getOrCreateStatsLabel()
	if statsLabel then
		return statsLabel
	end

	local playerGui = player:WaitForChild("PlayerGui")
	local gui = playerGui:FindFirstChild("TrainingGuiRuntime")
	if not gui then
		gui = Instance.new("ScreenGui")
		gui.Name = "TrainingGuiRuntime"
		gui.ResetOnSpawn = false
		gui.Parent = playerGui
	end

	statsLabel = gui:FindFirstChild("Stats")
	if not statsLabel then
		statsLabel = Instance.new("TextLabel")
		statsLabel.Name = "Stats"
		statsLabel.AnchorPoint = Vector2.new(1, 0)
		statsLabel.BackgroundColor3 = Color3.fromRGB(20, 23, 30)
		statsLabel.BackgroundTransparency = 0.12
		statsLabel.BorderSizePixel = 0
		statsLabel.Font = Enum.Font.GothamBold
		statsLabel.Position = UDim2.new(1, -18, 0, 14)
		statsLabel.Size = UDim2.fromOffset(230, 76)
		statsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		statsLabel.TextSize = 16
		statsLabel.TextWrapped = true
		statsLabel.Parent = gui

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = statsLabel
	end

	return statsLabel
end

local function updateStats(profile)
	local label = getOrCreateStatsLabel()
	local level = profile.Level or 1
	label.Text = string.format("Lv.%d %s\nXP %d    Coins %d", level, i18n.t("ranks." .. tostring(level)), profile.XP or 0, profile.Coins or 0)
end

function RewardClientController.Init()
	getOrCreateStatsLabel().Text = string.format("Lv.1 %s\nXP 0    Coins 0", i18n.t("ranks.1"))

	progressRemote.OnClientEvent:Connect(function(action, payload)
		if action == "ProgressUpdated" then
			updateStats(payload)
		end
	end)
end

return RewardClientController
