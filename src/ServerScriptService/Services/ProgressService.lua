local Players = game:GetService("Players")

local ProgressService = {}

local dataService = nil
local rankDefinitions = nil
local progressRemote = nil
local profiles = {}
local changedEvent = Instance.new("BindableEvent")

ProgressService.Changed = changedEvent.Event

local function cloneForClient(profile)
	local completedStages = {}
	for stageId, isCompleted in pairs(profile.CompletedStages) do
		completedStages[stageId] = isCompleted
	end

	return {
		XP = profile.XP,
		Coins = profile.Coins,
		Level = profile.Level,
		RankTitle = profile.RankTitle,
		CompletedStages = completedStages,
	}
end

local function applyRank(profile)
	local rank = rankDefinitions.GetRankForXp(profile.XP)
	profile.Level = rank.level
	profile.RankTitle = rank.title
end

local function fireChanged(player)
	local profile = profiles[player]
	if not profile then
		return
	end

	local clientProfile = cloneForClient(profile)
	changedEvent:Fire(player, clientProfile)

	if progressRemote then
		progressRemote:FireClient(player, "ProgressUpdated", clientProfile)
	end
end

local function onPlayerAdded(player)
	local profile = dataService.LoadPlayer(player)
	applyRank(profile)
	profiles[player] = profile

	task.defer(function()
		fireChanged(player)
	end)
end

local function onPlayerRemoving(player)
	local profile = profiles[player]
	if profile then
		dataService.SavePlayer(player, profile)
		profiles[player] = nil
	end
end

function ProgressService.Init(nextDataService, nextRankDefinitions, nextProgressRemote)
	dataService = nextDataService
	rankDefinitions = nextRankDefinitions
	progressRemote = nextProgressRemote

	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)

	for _, player in ipairs(Players:GetPlayers()) do
		onPlayerAdded(player)
	end
end

function ProgressService.GetProfile(player)
	return profiles[player]
end

function ProgressService.GetClientProfile(player)
	local profile = profiles[player]
	if not profile then
		return nil
	end

	return cloneForClient(profile)
end

function ProgressService.AwardStage(player, stageDefinition)
	local profile = profiles[player]
	if not profile then
		return nil
	end

	local alreadyCompleted = profile.CompletedStages[stageDefinition.id] == true
	local xp = 0
	local coins = 0

	if not alreadyCompleted then
		xp = stageDefinition.rewardXp or 0
		coins = stageDefinition.rewardCoins or 0
		profile.XP += xp
		profile.Coins += coins
		profile.CompletedStages[stageDefinition.id] = true
		applyRank(profile)
		fireChanged(player)
	end

	return {
		xp = xp,
		coins = coins,
		level = profile.Level,
		rankTitle = profile.RankTitle,
		alreadyCompleted = alreadyCompleted,
	}
end

return ProgressService
