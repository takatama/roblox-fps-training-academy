local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("Shared")
local stageDefinitions = require(shared:WaitForChild("StageDefinitions"))
local rankDefinitions = require(shared:WaitForChild("RankDefinitions"))
local config = require(shared:WaitForChild("Config"))

local services = script.Parent:WaitForChild("Services")
local DataService = require(services:WaitForChild("DataService"))
local ProgressService = require(services:WaitForChild("ProgressService"))
local RewardService = require(services:WaitForChild("RewardService"))
local LeaderstatsService = require(services:WaitForChild("LeaderstatsService"))
local StageService = require(services:WaitForChild("StageService"))

local remotesRoot = ReplicatedStorage:FindFirstChild("Remotes")
if not remotesRoot then
	remotesRoot = Instance.new("Folder")
	remotesRoot.Name = "Remotes"
	remotesRoot.Parent = ReplicatedStorage
end

local remoteFolder = remotesRoot:FindFirstChild(config.RemoteFolderName)
if not remoteFolder then
	remoteFolder = Instance.new("Folder")
	remoteFolder.Name = config.RemoteFolderName
	remoteFolder.Parent = remotesRoot
end

local function ensureRemoteEvent(name)
	local remote = remoteFolder:FindFirstChild(name)
	if not remote then
		remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = remoteFolder
	end

	return remote
end

local remotes = {
	StageEvent = ensureRemoteEvent("StageEvent"),
	ProgressEvent = ensureRemoteEvent("ProgressEvent"),
	StageSelectEvent = ensureRemoteEvent("StageSelectEvent"),
	CrouchStateEvent = ensureRemoteEvent("CrouchStateEvent"),
}

DataService.Init()
ProgressService.Init(DataService, rankDefinitions, remotes.ProgressEvent)
LeaderstatsService.Init(ProgressService)
RewardService.Init(ProgressService)
StageService.Init(stageDefinitions, RewardService, remotes)
