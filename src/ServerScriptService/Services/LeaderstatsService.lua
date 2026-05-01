local Players = game:GetService("Players")

local LeaderstatsService = {}

local progressService = nil

local function ensureValue(parent, className, name)
	local value = parent:FindFirstChild(name)
	if not value then
		value = Instance.new(className)
		value.Name = name
		value.Parent = parent
	end

	return value
end

local function updateLeaderstats(player, profile)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
	end

	ensureValue(leaderstats, "IntValue", "Level").Value = profile.Level
	ensureValue(leaderstats, "IntValue", "Coins").Value = profile.Coins
end

local function onPlayerAdded(player)
	local profile = progressService.GetClientProfile(player)
	if profile then
		updateLeaderstats(player, profile)
	end
end

function LeaderstatsService.Init(nextProgressService)
	progressService = nextProgressService

	progressService.Changed:Connect(function(player, profile)
		updateLeaderstats(player, profile)
	end)

	Players.PlayerAdded:Connect(onPlayerAdded)

	for _, player in ipairs(Players:GetPlayers()) do
		onPlayerAdded(player)
	end
end

return LeaderstatsService
