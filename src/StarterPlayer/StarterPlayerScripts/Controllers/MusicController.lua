local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local MusicController = {}

local config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

function MusicController.Init()
	if not config.BackgroundMusicSoundId or config.BackgroundMusicSoundId == "" then
		return
	end

	local existing = SoundService:FindFirstChild("TrainingAcademyBgm")
	if existing and existing:IsA("Sound") then
		if not existing.IsPlaying then
			existing:Play()
		end
		return
	end

	local music = Instance.new("Sound")
	music.Name = "TrainingAcademyBgm"
	music.SoundId = config.BackgroundMusicSoundId
	music.Volume = config.BackgroundMusicVolume or 0.25
	music.Looped = true
	music.Parent = SoundService
	music:Play()
end

return MusicController
