local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local SprintController = {}

local player = Players.LocalPlayer
local config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local isSprinting = false

local function getHumanoid()
	local character = player.Character
	if not character then
		return nil
	end

	return character:FindFirstChildOfClass("Humanoid")
end

local function applySpeed()
	local humanoid = getHumanoid()
	if not humanoid then
		return
	end

	if isSprinting then
		humanoid.WalkSpeed = config.PlayerSprintSpeed
	else
		humanoid.WalkSpeed = config.PlayerWalkSpeed
	end
end

function SprintController.Init()
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end

		if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
			isSprinting = true
			applySpeed()
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
			isSprinting = false
			applySpeed()
		end
	end)

	player.CharacterAdded:Connect(function()
		isSprinting = false
		task.wait(0.1)
		applySpeed()
	end)

	applySpeed()
end

return SprintController
