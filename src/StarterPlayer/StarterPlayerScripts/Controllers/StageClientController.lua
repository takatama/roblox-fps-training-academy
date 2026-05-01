local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local StageClientController = {}

local player = Players.LocalPlayer
local config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local stageDefinitions = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("StageDefinitions"))
local i18n = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Localization"))

local stageRemote = ReplicatedStorage
	:WaitForChild("Remotes")
	:WaitForChild(config.RemoteFolderName)
	:WaitForChild("StageEvent")

local stageSelectRemote = ReplicatedStorage
	:WaitForChild("Remotes")
	:WaitForChild(config.RemoteFolderName)
	:WaitForChild("StageSelectEvent")

local labels = {}
local showToast = nil
local stageSelectPanel = nil
local modalButton = nil
local menuOpen = false

local function forceMouseState(isOpen)
	if isOpen then
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
	else
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		UserInputService.MouseIconEnabled = false
	end
end

local function setMenuOpen(isOpen)
	menuOpen = isOpen
	player:SetAttribute("StageMenuOpen", isOpen)

	if modalButton then
		modalButton.Visible = isOpen
		modalButton.Modal = isOpen
	end

	if stageSelectPanel then
		stageSelectPanel.Visible = isOpen
	end

	if isOpen then
		player.CameraMode = Enum.CameraMode.Classic
		player.CameraMinZoomDistance = 0.5
		player.CameraMaxZoomDistance = 12
		forceMouseState(true)
	else
		player.CameraMode = Enum.CameraMode.LockFirstPerson
		player.CameraMinZoomDistance = 0.5
		player.CameraMaxZoomDistance = 0.5
		forceMouseState(false)
		task.delay(0.1, function()
			if not menuOpen then
				forceMouseState(false)
			end
		end)
		task.delay(0.35, function()
			if not menuOpen then
				forceMouseState(false)
			end
		end)
	end
end

local function createLabel(parent, name, position, size, textSize, font)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Font = font or Enum.Font.GothamMedium
	label.Position = position
	label.Size = size
	label.TextColor3 = Color3.fromRGB(245, 247, 250)
	label.TextSize = textSize
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = parent
	return label
end

local function playSound(soundId, volume)
	if not soundId or soundId == "" then
		return
	end

	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = volume or 0.5
	sound.Parent = SoundService
	sound:Play()
	sound.Ended:Connect(function()
		sound:Destroy()
	end)
end

local function emitTargetVfx(position)
	local anchor = Instance.new("Part")
	anchor.Name = "TargetHitVfx"
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.Transparency = 1
	anchor.Size = Vector3.new(0.2, 0.2, 0.2)
	anchor.Position = position
	anchor.Parent = Workspace

	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 245, 170)),
		ColorSequenceKeypoint.new(0.45, Color3.fromRGB(255, 120, 80)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 210, 255)),
	})
	emitter.Lifetime = NumberRange.new(0.45, 0.85)
	emitter.Rate = 0
	emitter.Rotation = NumberRange.new(0, 360)
	emitter.RotSpeed = NumberRange.new(-220, 220)
	emitter.Speed = NumberRange.new(16, 28)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.55),
		NumberSequenceKeypoint.new(0.55, 0.32),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Parent = anchor
	emitter:Emit(56)

	local flash = Instance.new("ParticleEmitter")
	flash.Color = ColorSequence.new(Color3.fromRGB(255, 255, 210), Color3.fromRGB(255, 120, 70))
	flash.Lifetime = NumberRange.new(0.12, 0.22)
	flash.Rate = 0
	flash.Speed = NumberRange.new(4, 8)
	flash.SpreadAngle = Vector2.new(180, 180)
	flash.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1.2),
		NumberSequenceKeypoint.new(1, 0),
	})
	flash.Parent = anchor
	flash:Emit(14)

	task.delay(1.6, function()
		if anchor.Parent then
			anchor:Destroy()
		end
	end)
end

local function emitClearConfetti()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local camera = Workspace.CurrentCamera

	local anchor = Instance.new("Part")
	anchor.Name = "StageClearConfetti"
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.Transparency = 1
	anchor.Size = Vector3.new(0.2, 0.2, 0.2)

	if root then
		anchor.Position = root.Position + Vector3.new(0, 7, 0)
	elseif camera then
		anchor.Position = camera.CFrame.Position + camera.CFrame.LookVector * 8
	else
		anchor.Position = Vector3.new(0, 8, 0)
	end

	anchor.Parent = Workspace

	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 214, 80)),
		ColorSequenceKeypoint.new(0.35, Color3.fromRGB(80, 210, 255)),
		ColorSequenceKeypoint.new(0.7, Color3.fromRGB(255, 100, 160)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 240, 150)),
	})
	emitter.Lifetime = NumberRange.new(1.2, 1.8)
	emitter.Rate = 0
	emitter.Rotation = NumberRange.new(0, 360)
	emitter.RotSpeed = NumberRange.new(-180, 180)
	emitter.Speed = NumberRange.new(18, 26)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.35),
		NumberSequenceKeypoint.new(0.75, 0.28),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Parent = anchor
	emitter:Emit(90)

	task.delay(2.4, function()
		if anchor.Parent then
			anchor:Destroy()
		end
	end)
end

local function getOrCreateGui()
	local playerGui = player:WaitForChild("PlayerGui")
	local gui = playerGui:FindFirstChild("TrainingGuiRuntime")
	if not gui then
		gui = Instance.new("ScreenGui")
		gui.Name = "TrainingGuiRuntime"
		gui.IgnoreGuiInset = false
		gui.ResetOnSpawn = false
		gui.Parent = playerGui
	end

	if labels.Title then
		return gui
	end

	local bootTitle = gui:FindFirstChild("BootTitle")
	if bootTitle and bootTitle:IsA("GuiObject") then
		bootTitle.Visible = false
	end

	local topPanel = gui:FindFirstChild("TopPanel")
	if not topPanel then
		topPanel = Instance.new("Frame")
		topPanel.Name = "TopPanel"
		topPanel.AnchorPoint = Vector2.new(0.5, 0)
		topPanel.BackgroundColor3 = Color3.fromRGB(20, 23, 30)
		topPanel.BackgroundTransparency = 0.12
		topPanel.BorderSizePixel = 0
		topPanel.Position = UDim2.new(0.5, 0, 0, 14)
		topPanel.Size = UDim2.fromOffset(720, 118)
		topPanel.Parent = gui

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = topPanel

		local padding = Instance.new("UIPadding")
		padding.PaddingLeft = UDim.new(0, 18)
		padding.PaddingRight = UDim.new(0, 18)
		padding.PaddingTop = UDim.new(0, 12)
		padding.PaddingBottom = UDim.new(0, 12)
		padding.Parent = topPanel
	end

	labels.Title = createLabel(topPanel, "Title", UDim2.fromOffset(0, 0), UDim2.new(1, -150, 0, 28), 22, Enum.Font.GothamBold)
	labels.Instruction = createLabel(topPanel, "Instruction", UDim2.fromOffset(0, 34), UDim2.new(1, -10, 0, 48), 18, Enum.Font.GothamMedium)
	labels.Progress = createLabel(topPanel, "Progress", UDim2.new(1, -132, 0, 0), UDim2.fromOffset(132, 28), 18, Enum.Font.GothamBold)
	labels.Progress.TextXAlignment = Enum.TextXAlignment.Right

	local toast = gui:FindFirstChild("RewardToast")
	if not toast then
		toast = Instance.new("TextLabel")
		toast.Name = "RewardToast"
		toast.AnchorPoint = Vector2.new(0.5, 0)
		toast.BackgroundColor3 = Color3.fromRGB(50, 74, 62)
		toast.BackgroundTransparency = 0.08
		toast.BorderSizePixel = 0
		toast.Font = Enum.Font.GothamBold
		toast.Position = UDim2.new(0.5, 0, 0, 142)
		toast.Size = UDim2.fromOffset(520, 46)
		toast.TextColor3 = Color3.fromRGB(255, 255, 255)
		toast.TextSize = 18
		toast.TextTransparency = 1
		toast.Visible = false
		toast.Parent = gui

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = toast
	end

	labels.Toast = toast

	modalButton = gui:FindFirstChild("StageMenuModal")
	if not modalButton then
		modalButton = Instance.new("TextButton")
		modalButton.Name = "StageMenuModal"
		modalButton.BackgroundTransparency = 1
		modalButton.BorderSizePixel = 0
		modalButton.Modal = false
		modalButton.Text = ""
		modalButton.Visible = false
		modalButton.ZIndex = 20
		modalButton.Size = UDim2.fromScale(1, 1)
		modalButton.Parent = gui
	end

	local stageSelect = gui:FindFirstChild("StageSelect")
	if not stageSelect then
		stageSelect = Instance.new("Frame")
		stageSelect.Name = "StageSelect"
		stageSelect.BackgroundColor3 = Color3.fromRGB(20, 23, 30)
		stageSelect.BackgroundTransparency = 0.12
		stageSelect.BorderSizePixel = 0
		stageSelect.Position = UDim2.fromOffset(14, 64)
		stageSelect.Size = UDim2.fromOffset(170, 450)
		stageSelect.Visible = false
		stageSelect.Active = true
		stageSelect.ZIndex = 30
		stageSelect.Parent = gui
		stageSelectPanel = stageSelect

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = stageSelect

		local padding = Instance.new("UIPadding")
		padding.PaddingLeft = UDim.new(0, 10)
		padding.PaddingRight = UDim.new(0, 10)
		padding.PaddingTop = UDim.new(0, 10)
		padding.PaddingBottom = UDim.new(0, 10)
		padding.Parent = stageSelect

		local list = Instance.new("UIListLayout")
		list.Padding = UDim.new(0, 6)
		list.SortOrder = Enum.SortOrder.LayoutOrder
		list.Parent = stageSelect

		local title = Instance.new("TextLabel")
		title.Name = "Title"
		title.BackgroundTransparency = 1
		title.Font = Enum.Font.GothamBold
		title.LayoutOrder = 0
		title.Size = UDim2.new(1, 0, 0, 22)
		title.Text = i18n.t("ui.stageSelectTitle")
		title.TextColor3 = Color3.fromRGB(245, 247, 250)
		title.TextSize = 15
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.ZIndex = 31
		title.Parent = stageSelect

		for index, stageId in ipairs(stageDefinitions.Order) do
			local stage = stageDefinitions.GetStage(stageId)
			local button = Instance.new("TextButton")
			button.Name = "StageButton_" .. stageId
			button.AutoButtonColor = true
			button.BackgroundColor3 = Color3.fromRGB(39, 45, 56)
			button.BorderSizePixel = 0
			button.Font = Enum.Font.GothamBold
			button.LayoutOrder = index
			button.Size = UDim2.new(1, 0, 0, 34)
			button.Text = string.format("%d. %s", index, i18n.stageShortTitle(stageId))
			button.TextColor3 = Color3.fromRGB(255, 255, 255)
			button.TextSize = 13
			button.TextWrapped = true
			button.ZIndex = 31
			button.Parent = stageSelect

			local buttonCorner = Instance.new("UICorner")
			buttonCorner.CornerRadius = UDim.new(0, 6)
			buttonCorner.Parent = button

			button.Activated:Connect(function()
				stageSelectRemote:FireServer(stageId)
				showToast(i18n.t("ui.movingToStage", {
					stage = i18n.stageShortTitle(stageId),
				}))
				setMenuOpen(false)
			end)
		end
	else
		stageSelectPanel = stageSelect
	end

	return gui
end

showToast = function(text)
	getOrCreateGui()
	local toast = labels.Toast
	toast.Text = text
	toast.Visible = true
	toast.TextTransparency = 1
	toast.BackgroundTransparency = 1

	TweenService:Create(toast, TweenInfo.new(0.18), {
		TextTransparency = 0,
		BackgroundTransparency = 0.08,
	}):Play()

	task.delay(2.2, function()
		if toast.Parent then
			TweenService:Create(toast, TweenInfo.new(0.25), {
				TextTransparency = 1,
				BackgroundTransparency = 1,
			}):Play()
		end
	end)
end

local function hideTargetLocally(target)
	if typeof(target) ~= "Instance" then
		return
	end

	for _, descendant in ipairs(target:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.LocalTransparencyModifier = 1
		end
	end

	if target:IsA("BasePart") then
		target.LocalTransparencyModifier = 1
	end
end

local function restoreStageTargetsLocally(stageId)
	if typeof(stageId) ~= "string" then
		return
	end

	local generatedMap = Workspace:FindFirstChild("GeneratedTrainingMap")
	if not generatedMap then
		return
	end

	for _, descendant in ipairs(generatedMap:GetDescendants()) do
		local target = descendant
		if descendant:IsA("BasePart") and descendant.Parent and descendant.Parent:GetAttribute("StageId") == stageId then
			target = descendant.Parent
		end

		if descendant:IsA("BasePart") and target:GetAttribute("StageId") == stageId then
			descendant.LocalTransparencyModifier = 0
		end
	end
end

local function onStageStarted(payload)
	getOrCreateGui()
	restoreStageTargetsLocally(payload.id)
	labels.Title.Text = i18n.stageTitle(payload.id)
	labels.Instruction.Text = i18n.stageInstruction(payload.id)
	labels.Progress.Text = string.format("%d / %d", payload.stageIndex or 1, payload.stageTotal or 1)

	if payload.progressText and payload.progressText ~= "" then
		labels.Progress.Text = payload.progressText
	end
end

local function onStageProgress(payload)
	getOrCreateGui()
	if payload.progressKey then
		labels.Progress.Text = i18n.t(payload.progressKey, payload.progressArgs)
	else
		labels.Progress.Text = payload.progressText or ""
	end
end

local function onStageCompleted(payload)
	local reward = payload.reward or {}
	local text = i18n.t("ui.clear")

	if reward.alreadyCompleted then
		text = i18n.t("ui.alreadyCleared")
	else
		text = i18n.t("ui.clearReward", {
			xp = reward.xp or 0,
			coins = reward.coins or 0,
		})
	end

	playSound(config.StageClearCheerSoundId, 0.8)
	emitClearConfetti()
	showToast(text)
end

local function onTargetHit(payload)
	playSound(config.TargetHitSoundId, 0.55)
	if typeof(payload.target) == "Instance" and payload.target:IsA("BasePart") then
		emitTargetVfx(payload.target.Position)
	end
	if not payload.keepVisible then
		hideTargetLocally(payload.target)
	end
	showToast(i18n.t("ui.hit", {
		hit = payload.hitCount or 0,
		total = payload.targetCount or 0,
	}))
end

function StageClientController.Init()
	getOrCreateGui()
	setMenuOpen(false)
	labels.Title.Text = config.GameName
	labels.Instruction.Text = i18n.t("ui.loading")
	labels.Progress.Text = ""

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed and input.KeyCode ~= Enum.KeyCode.M then
			return
		end

		if input.KeyCode == Enum.KeyCode.M then
			setMenuOpen(not menuOpen)
		elseif input.UserInputType == Enum.UserInputType.MouseButton1 and not menuOpen then
			playSound(config.TargetClickSoundId, 0.25)
		end
	end)

	stageRemote.OnClientEvent:Connect(function(action, payload)
		if action == "StageStarted" then
			onStageStarted(payload)
		elseif action == "StageProgress" then
			onStageProgress(payload)
		elseif action == "StageCompleted" then
			onStageCompleted(payload)
		elseif action == "TargetHit" then
			onTargetHit(payload)
		end
	end)
end

return StageClientController
