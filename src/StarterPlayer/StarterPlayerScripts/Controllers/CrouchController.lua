local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local CrouchController = {}

local player = Players.LocalPlayer
local config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local crouchRemote = ReplicatedStorage
	:WaitForChild("Remotes")
	:WaitForChild(config.RemoteFolderName)
	:WaitForChild("CrouchStateEvent")
local isCrouching = false
local lastSentCrouchState = nil

local function debugLog(message)
	if config.DebugCrouch then
		print("[CrouchClient] " .. message)
	end
end

local function sendCrouchState()
	if lastSentCrouchState == isCrouching then
		return
	end

	lastSentCrouchState = isCrouching
	debugLog("send crouch state = " .. tostring(isCrouching))
	crouchRemote:FireServer(isCrouching)
end

local function updateLowTunnelBlocks()
	for _, block in ipairs(CollectionService:GetTagged("LowTunnelBlock")) do
		if block:IsA("BasePart") then
			block.CanCollide = not isCrouching
			block.LocalTransparencyModifier = isCrouching and 0.7 or 0
		end
	end
end

local function getHumanoid()
	local character = player.Character
	if not character then
		return nil
	end

	return character:FindFirstChildOfClass("Humanoid")
end

local function applyCrouch()
	local humanoid = getHumanoid()
	if not humanoid then
		return
	end

	if isCrouching then
		humanoid.WalkSpeed = config.PlayerCrouchSpeed
		humanoid.JumpPower = 0
		humanoid.CameraOffset = Vector3.new(0, -1.2, 0)
	else
		humanoid.WalkSpeed = config.PlayerWalkSpeed
		humanoid.JumpPower = config.PlayerJumpPower
		humanoid.CameraOffset = Vector3.zero
	end

	debugLog(string.format(
		"apply crouch=%s WalkSpeed=%s JumpPower=%s",
		tostring(isCrouching),
		tostring(humanoid.WalkSpeed),
		tostring(humanoid.JumpPower)
	))

	updateLowTunnelBlocks()
	sendCrouchState()
end

function CrouchController.Init()
	debugLog("Init")

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if input.KeyCode == Enum.KeyCode.W or input.KeyCode == Enum.KeyCode.A or input.KeyCode == Enum.KeyCode.S or input.KeyCode == Enum.KeyCode.D or input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl then
			debugLog("InputBegan key=" .. input.KeyCode.Name .. " gameProcessed=" .. tostring(gameProcessed))
		end

		if gameProcessed and input.KeyCode ~= Enum.KeyCode.LeftControl and input.KeyCode ~= Enum.KeyCode.RightControl then
			return
		end

		if input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl or input.KeyCode == Enum.KeyCode.C then
			isCrouching = not isCrouching
			applyCrouch()
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.W or input.KeyCode == Enum.KeyCode.A or input.KeyCode == Enum.KeyCode.S or input.KeyCode == Enum.KeyCode.D or input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl then
			debugLog("InputEnded key=" .. input.KeyCode.Name)
		end

		-- しゃがみは押しっぱなしではなく切り替え式です。
		-- 移動はRoblox標準のWASD操作に任せます。
	end)

	player.CharacterAdded:Connect(function()
		isCrouching = false
		task.wait(0.1)
		applyCrouch()
	end)

	CollectionService:GetInstanceAddedSignal("LowTunnelBlock"):Connect(updateLowTunnelBlocks)

	applyCrouch()
end

return CrouchController
