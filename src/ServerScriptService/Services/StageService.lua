local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local StageService = {}

local stageDefinitions = nil
local rewardService = nil
local remotes = nil
local generatedMap = nil
local playerStates = {}
local clickedTargetsByPlayer = {}
local completedDebounce = {}
local crouchingPlayers = {}
local getStageIndex = nil
local setStageTargetsVisible = nil

local COLORS = {
	Floor = Color3.fromRGB(72, 79, 88),
	Wall = Color3.fromRGB(42, 46, 54),
	Accent = Color3.fromRGB(78, 142, 168),
	Goal = Color3.fromRGB(255, 214, 80),
	Hazard = Color3.fromRGB(220, 64, 64),
	Checkpoint = Color3.fromRGB(88, 214, 141),
	Target = Color3.fromRGB(235, 92, 92),
	TargetCenter = Color3.fromRGB(255, 245, 170),
	Text = Color3.fromRGB(255, 255, 255),
}

local function createPart(parent, name, size, position, color)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.Size = size
	part.Position = position
	part.Color = color
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function createWedge(parent, name, size, position, color)
	local wedge = Instance.new("WedgePart")
	wedge.Name = name
	wedge.Anchored = true
	wedge.Size = size
	wedge.Position = position
	wedge.Color = color
	wedge.TopSurface = Enum.SurfaceType.Smooth
	wedge.BottomSurface = Enum.SurfaceType.Smooth
	wedge.Parent = parent
	return wedge
end

local function debugCrouch(message)
	if config.DebugCrouch then
		print("[CrouchServer] " .. message)
	end
end

local function createFloorLabel(parent, name, position, text)
	local labelPart = createPart(parent, name, Vector3.new(22, 0.1, 7), position, Color3.fromRGB(34, 39, 48))
	labelPart.CanCollide = false
	labelPart.Material = Enum.Material.SmoothPlastic

	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Face = Enum.NormalId.Top
	surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surfaceGui.PixelsPerStud = 45
	surfaceGui.Parent = labelPart

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBold
	label.Text = text
	label.TextColor3 = COLORS.Text
	label.TextScaled = true
	label.TextWrapped = true
	label.Rotation = 270
	label.Parent = surfaceGui

	return labelPart
end

local function createFloorGlyph(parent, name, position, text, color)
	local glyphPart = createPart(parent, name, Vector3.new(11, 0.1, 11), position, Color3.fromRGB(34, 39, 48))
	glyphPart.CanCollide = false
	glyphPart.Transparency = 1

	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Face = Enum.NormalId.Top
	surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surfaceGui.PixelsPerStud = 45
	surfaceGui.Parent = glyphPart

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBold
	label.Text = text
	label.TextColor3 = color
	label.TextScaled = true
	label.TextWrapped = true
	label.Rotation = 270
	label.Parent = surfaceGui

	return glyphPart
end

local function getStageMarkerText(stageId)
	return "↑ Stage " .. tostring(getStageIndex(stageId))
end

local function createStageMarker(parent, stage, position)
	local label = createFloorLabel(parent, "StageName", position, getStageMarkerText(stage.id))
	label.Size = Vector3.new(22, 0.1, 7)
	return label
end

local function createArrowGuide(parent, name, position, color)
	local rows = 8
	local rowDepth = 0.8
	local totalDepth = rows * rowDepth

	for row = 1, rows do
		local progress = (row - 1) / (rows - 1)
		local width = 7.5 * (1 - progress) + 0.9
		local zOffset = -totalDepth / 2 + (row - 0.5) * rowDepth
		local strip = createPart(parent, name .. "_TriangleRow" .. row, Vector3.new(width, 0.16, rowDepth), position + Vector3.new(0, 0, zOffset), color)
		strip.CanCollide = false
		strip.Material = Enum.Material.Neon
	end

	local glowAnchor = createPart(parent, name .. "_GlowAnchor", Vector3.new(0.2, 0.2, 0.2), position, color)
	glowAnchor.CanCollide = false
	glowAnchor.Transparency = 1

	local glow = Instance.new("PointLight")
	glow.Name = name .. "_Glow"
	glow.Brightness = 0.45
	glow.Color = color
	glow.Range = 10
	glow.Parent = glowAnchor
end

local function getPlayerFromTouchedPart(hit)
	local character = hit:FindFirstAncestorOfClass("Model")
	if not character then
		return nil
	end

	return Players:GetPlayerFromCharacter(character)
end

getStageIndex = function(stageId)
	for index, id in ipairs(stageDefinitions.Order) do
		if id == stageId then
			return index
		end
	end

	return 1
end

local function teleportToStage(player, stageDefinition)
	local character = player.Character
	if not character then
		return
	end

	local root = character:WaitForChild("HumanoidRootPart", 5)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = config.PlayerWalkSpeed
		humanoid.JumpPower = config.PlayerJumpPower
	end

	if root then
		root.CFrame = CFrame.new(stageDefinition.spawnPosition) * CFrame.Angles(0, math.rad(180), 0)
	end
end

local function teleportPlayerToPosition(player, position)
	local character = player.Character
	if not character then
		return
	end

	local root = character:FindFirstChild("HumanoidRootPart")
	if root then
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
		root.CFrame = CFrame.new(position) * CFrame.Angles(0, math.rad(180), 0)
	end
end

local function sendStageStarted(player, stageDefinition)
	local state = playerStates[player]
	local progressText = ""

	if (
		stageDefinition.type == "targets"
		or stageDefinition.type == "moving_targets"
		or stageDefinition.type == "sprint_stop_targets"
		or stageDefinition.type == "jump_targets"
		or stageDefinition.type == "training_arena"
	) and state then
		progressText = string.format("%d / %d", state.hitCount or 0, stageDefinition.targetCount or 0)
	end

	remotes.StageEvent:FireClient(player, "StageStarted", {
		id = stageDefinition.id,
		title = stageDefinition.title,
		shortTitle = stageDefinition.shortTitle,
		instruction = stageDefinition.instruction,
		type = stageDefinition.type,
		stageIndex = getStageIndex(stageDefinition.id),
		stageTotal = #stageDefinitions.Order,
		progressText = progressText,
	})
end

local function startStage(player, stageDefinition)
	playerStates[player] = {
		stageId = stageDefinition.id,
		hitCount = 0,
		checkpointPosition = stageDefinition.spawnPosition,
		hazardDebounce = false,
	}
	clickedTargetsByPlayer[player] = {}
	completedDebounce[player] = nil

	if stageDefinition.type == "sprint_stop_targets" or stageDefinition.type == "jump_targets" then
		setStageTargetsVisible(stageDefinition, false)
	else
		setStageTargetsVisible(stageDefinition, true)
	end

	if stageDefinition.type == "training_arena" and generatedMap then
		local stageFolder = generatedMap:FindFirstChild(stageDefinition.id)
		local goal = stageFolder and stageFolder:FindFirstChild("GoalZone")
		if goal and goal:IsA("BasePart") then
			goal.Transparency = 1
			goal.CanTouch = false
		end
	end

	teleportToStage(player, stageDefinition)
	sendStageStarted(player, stageDefinition)
end

local function completeStage(player, stageDefinition)
	if completedDebounce[player] == stageDefinition.id then
		return
	end
	completedDebounce[player] = stageDefinition.id

	local reward = rewardService.GrantStageReward(player, stageDefinition)
	remotes.StageEvent:FireClient(player, "StageCompleted", {
		id = stageDefinition.id,
		title = stageDefinition.title,
		reward = reward,
	})

	local nextStage = stageDefinitions.GetNextStage(stageDefinition.id)
	if nextStage then
		task.delay(2.5, function()
			if player.Parent then
				startStage(player, nextStage)
			end
		end)
	end
end

local function createLobby(parent)
	createPart(parent, "LobbyFloor", Vector3.new(56, 1, 34), Vector3.new(40, 0, 0), Color3.fromRGB(55, 62, 72))
	createFloorLabel(parent, "LobbyTitle", Vector3.new(40, 0.6, -8), "FPS Training Academy")
end

local function createWalkStage(parent, stage)
	local folder = Instance.new("Folder")
	folder.Name = stage.id
	folder.Parent = parent

	createPart(folder, "Floor", Vector3.new(30, 1, 82), stage.basePosition, COLORS.Floor)
	createPart(folder, "LeftWall", Vector3.new(1, 8, 82), stage.basePosition + Vector3.new(-15.5, 4, 0), COLORS.Wall)
	createPart(folder, "RightWall", Vector3.new(1, 8, 82), stage.basePosition + Vector3.new(15.5, 4, 0), COLORS.Wall)
	createStageMarker(folder, stage, stage.basePosition + Vector3.new(0, 0.6, -34))

	for index = 1, 5 do
		createArrowGuide(folder, "ForwardArrow" .. index, stage.basePosition + Vector3.new(0, 0.65, -29 + index * 11), COLORS.Accent)
	end

	local goal = createPart(folder, "GoalZone", Vector3.new(14, 1.5, 8), stage.goalPosition, COLORS.Goal)
	goal.Material = Enum.Material.Neon
	goal.Transparency = 0.15
	goal:SetAttribute("StageId", stage.id)
	CollectionService:AddTag(goal, "GoalZone")

	goal.Touched:Connect(function(hit)
		local player = getPlayerFromTouchedPart(hit)
		if player then
			local state = playerStates[player]
			if state and state.stageId == stage.id then
				completeStage(player, stage)
			end
		end
	end)
end

local function createTarget(parent, stage, targetId, position)
	local targetSize = Vector3.new(4, 4, 0.4)
	if stage.type == "moving_targets" then
		targetSize = Vector3.new(5, 5, 0.4)
	end

	local target = createPart(parent, "Target_" .. targetId, targetSize, position, COLORS.Target)
	target.Material = Enum.Material.SmoothPlastic
	target:SetAttribute("StageId", stage.id)
	target:SetAttribute("TargetId", targetId)
	CollectionService:AddTag(target, "TrainingTarget")

	local center = createPart(target, "Center", Vector3.new(1.6, 1.6, 0.45), position + Vector3.new(0, 0, -0.04), COLORS.TargetCenter)
	center.Anchored = true
	center.CanCollide = false
	center.Parent = target

	local clickDetector = Instance.new("ClickDetector")
	clickDetector.MaxActivationDistance = 90
	clickDetector.Parent = target

	if stage.type == "sprint_stop_targets" or stage.type == "jump_targets" then
		target.Transparency = 1
		center.Transparency = 1
		clickDetector.MaxActivationDistance = 0
	end

	if stage.type == "moving_targets" then
		local moveDistance = 5 + (targetId % 2) * 2
		local moveTime = 2.6 + (targetId % 3) * 0.35
		local originalPosition = target.Position
		local originalCenterPosition = center.Position
		local tweenInfo = TweenInfo.new(moveTime, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
		local tween = TweenService:Create(target, tweenInfo, {
			Position = originalPosition + Vector3.new(moveDistance, 0, 0),
		})
		local centerTween = TweenService:Create(center, tweenInfo, {
			Position = originalCenterPosition + Vector3.new(moveDistance, 0, 0),
		})
		tween:Play()
		centerTween:Play()
	end

	clickDetector.MouseClick:Connect(function(player)
		local state = playerStates[player]
		if not state or state.stageId ~= stage.id then
			return
		end
		if stage.type == "sprint_stop_targets" and not state.stopReached then
			return
		end
		if stage.type == "jump_targets" and not state.jumpTargetReady then
			return
		end

		clickedTargetsByPlayer[player] = clickedTargetsByPlayer[player] or {}
		if clickedTargetsByPlayer[player][targetId] then
			return
		end

		clickedTargetsByPlayer[player][targetId] = true
		state.hitCount += 1

		remotes.StageEvent:FireClient(player, "TargetHit", {
			target = target,
			hitCount = state.hitCount,
			targetCount = stage.targetCount,
		})

		remotes.StageEvent:FireClient(player, "StageProgress", {
			id = stage.id,
			progressText = string.format("%d / %d", state.hitCount, stage.targetCount),
		})

		if state.hitCount >= stage.targetCount then
			completeStage(player, stage)
		end
	end)

	return target
end

local function setTargetVisible(target, isVisible)
	if target:IsA("BasePart") then
		target.Transparency = isVisible and 0 or 1
	end

	for _, descendant in ipairs(target:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Transparency = isVisible and 0 or 1
		elseif descendant:IsA("ClickDetector") then
			descendant.MaxActivationDistance = isVisible and 90 or 0
		end
	end
end

local function revealStageTargets(folder)
	for _, child in ipairs(folder:GetChildren()) do
		if child:IsA("BasePart") and CollectionService:HasTag(child, "TrainingTarget") then
			setTargetVisible(child, true)
		end
	end
end

setStageTargetsVisible = function(stageDefinition, isVisible)
	if not generatedMap then
		return
	end

	local stageFolder = generatedMap:FindFirstChild(stageDefinition.id)
	if not stageFolder then
		return
	end

	for _, child in ipairs(stageFolder:GetChildren()) do
		if child:IsA("BasePart") and CollectionService:HasTag(child, "TrainingTarget") then
			if stageDefinition.type == "training_arena" and isVisible then
				child.Color = Color3.fromRGB(88, 170, 220)
				child.Material = Enum.Material.SmoothPlastic
				child:SetAttribute("Destroyed", false)
			end
			setTargetVisible(child, isVisible)
		end
	end
end

local function createTargetStage(parent, stage)
	local folder = Instance.new("Folder")
	folder.Name = stage.id
	folder.Parent = parent

	createPart(folder, "Floor", Vector3.new(42, 1, 76), stage.basePosition, COLORS.Floor)
	createPart(folder, "BackWall", Vector3.new(42, 18, 1), stage.basePosition + Vector3.new(0, 9, 34), COLORS.Wall)
	createPart(folder, "LeftWall", Vector3.new(1, 8, 76), stage.basePosition + Vector3.new(-21.5, 4, 0), COLORS.Wall)
	createPart(folder, "RightWall", Vector3.new(1, 8, 76), stage.basePosition + Vector3.new(21.5, 4, 0), COLORS.Wall)
	createStageMarker(folder, stage, stage.basePosition + Vector3.new(0, 0.6, -31))

	local startPad = createPart(folder, "StartPad", Vector3.new(10, 0.25, 8), stage.basePosition + Vector3.new(0, 0.75, -32), COLORS.Accent)
	startPad.Material = Enum.Material.Neon

	local startX = stage.basePosition.X - 15
	local startY = 5
	local z = stage.basePosition.Z + 33.4
	local targetId = 1

	for row = 0, 1 do
		for col = 0, 4 do
			createTarget(folder, stage, targetId, Vector3.new(startX + col * 7.5, startY + row * 6, z))
			targetId += 1
		end
	end
end

local function createMovingTargetStage(parent, stage)
	local folder = Instance.new("Folder")
	folder.Name = stage.id
	folder.Parent = parent

	createPart(folder, "Floor", Vector3.new(42, 1, 76), stage.basePosition, COLORS.Floor)
	createPart(folder, "BackWall", Vector3.new(42, 18, 1), stage.basePosition + Vector3.new(0, 9, 34), COLORS.Wall)
	createPart(folder, "LeftWall", Vector3.new(1, 8, 76), stage.basePosition + Vector3.new(-21.5, 4, 0), COLORS.Wall)
	createPart(folder, "RightWall", Vector3.new(1, 8, 76), stage.basePosition + Vector3.new(21.5, 4, 0), COLORS.Wall)
	createStageMarker(folder, stage, stage.basePosition + Vector3.new(0, 0.6, -31))

	local startPad = createPart(folder, "StartPad", Vector3.new(10, 0.25, 8), stage.basePosition + Vector3.new(0, 0.75, -32), COLORS.Accent)
	startPad.Material = Enum.Material.Neon

	local z = stage.basePosition.Z + 33.4
	local positions = {
		Vector3.new(stage.basePosition.X - 14, 6, z),
		Vector3.new(stage.basePosition.X - 7, 11, z),
		Vector3.new(stage.basePosition.X, 7, z),
		Vector3.new(stage.basePosition.X + 7, 12, z),
		Vector3.new(stage.basePosition.X + 14, 6, z),
	}

	for targetId, position in ipairs(positions) do
		createTarget(folder, stage, targetId, position)
	end
end

local function createJumpCourseStage(parent, stage)
	local folder = Instance.new("Folder")
	folder.Name = stage.id
	folder.Parent = parent

	createPart(folder, "StartFloor", Vector3.new(26, 1, 26), stage.basePosition + Vector3.new(0, 0, -28), COLORS.Floor)
	createPart(folder, "LandingFloor", Vector3.new(26, 1, 58), stage.basePosition + Vector3.new(0, 0, 18), COLORS.Floor)
	createPart(folder, "LeftWall", Vector3.new(1, 8, 86), stage.basePosition + Vector3.new(-13.5, 4, 2), COLORS.Wall)
	createPart(folder, "RightWall", Vector3.new(1, 8, 86), stage.basePosition + Vector3.new(13.5, 4, 2), COLORS.Wall)
	createStageMarker(folder, stage, stage.basePosition + Vector3.new(0, 0.6, -38))

	local jumpBlockColor = Color3.fromRGB(92, 103, 116)
	createPart(folder, "JumpBlockOne", Vector3.new(24, 3.4, 7), stage.basePosition + Vector3.new(0, 2.2, -8), jumpBlockColor)
	createPart(folder, "JumpBlockTwo", Vector3.new(24, 3.8, 7), stage.basePosition + Vector3.new(0, 2.4, 12), jumpBlockColor)
	createPart(folder, "GoalPlatform", Vector3.new(24, 4.2, 12), stage.basePosition + Vector3.new(0, 2.6, 36), jumpBlockColor)

	for index = 1, 4 do
		createArrowGuide(folder, "JumpGuide" .. index, stage.basePosition + Vector3.new(0, 0.75, -42 + index * 16), COLORS.Accent)
	end

	local resetZone = createPart(folder, "FallReset", Vector3.new(30, 1, 92), stage.basePosition + Vector3.new(0, -8, 2), Color3.fromRGB(30, 34, 40))
	resetZone.Transparency = 1
	resetZone.CanCollide = false
	resetZone.Touched:Connect(function(hit)
		local player = getPlayerFromTouchedPart(hit)
		if not player then
			return
		end

		local state = playerStates[player]
		if state and state.stageId == stage.id then
			teleportPlayerToPosition(player, stage.spawnPosition)
		end
	end)

	local goal = createPart(folder, "GoalZone", Vector3.new(14, 1.5, 8), stage.basePosition + Vector3.new(0, 5.45, 36), COLORS.Goal)
	goal.Material = Enum.Material.Neon
	goal.Transparency = 0.15
	goal:SetAttribute("StageId", stage.id)
	CollectionService:AddTag(goal, "GoalZone")

	goal.Touched:Connect(function(hit)
		local player = getPlayerFromTouchedPart(hit)
		if not player then
			return
		end

		local state = playerStates[player]
		if state and state.stageId == stage.id then
			completeStage(player, stage)
		end
	end)
end

local function createCheckpoint(folder, stage, name, position)
	local checkpoint = createPart(folder, name, Vector3.new(12, 0.35, 7), position, COLORS.Checkpoint)
	checkpoint.Material = Enum.Material.Neon
	checkpoint:SetAttribute("StageId", stage.id)
	CollectionService:AddTag(checkpoint, "Checkpoint")

	checkpoint.Touched:Connect(function(hit)
		local player = getPlayerFromTouchedPart(hit)
		if not player then
			return
		end

		local state = playerStates[player]
		if not state or state.stageId ~= stage.id then
			return
		end

		state.checkpointPosition = position + Vector3.new(0, 4, 0)
		remotes.StageEvent:FireClient(player, "StageProgress", {
			id = stage.id,
			progressKey = "progress.checkpoint",
		})
	end)

	return checkpoint
end

local function createHazard(folder, stage, name, size, position)
	local hazard = createPart(folder, name, size, position, COLORS.Hazard)
	hazard.Material = Enum.Material.Neon
	hazard.Transparency = 0.05
	hazard:SetAttribute("StageId", stage.id)
	CollectionService:AddTag(hazard, "Hazard")

	hazard.Touched:Connect(function(hit)
		local player = getPlayerFromTouchedPart(hit)
		if not player then
			return
		end

		local state = playerStates[player]
		if not state or state.stageId ~= stage.id or state.hazardDebounce then
			return
		end

		state.hazardDebounce = true
		local returnPosition = state.checkpointPosition or stage.spawnPosition
		remotes.StageEvent:FireClient(player, "StageProgress", {
			id = stage.id,
			progressKey = "progress.hazardReturn",
		})
		teleportPlayerToPosition(player, returnPosition)

		task.delay(1, function()
			if playerStates[player] then
				playerStates[player].hazardDebounce = false
			end
		end)
	end)

	return hazard
end

local function createLowTunnelBlock(folder, name, size, position)
	local block = createPart(folder, name, size, position, Color3.fromRGB(92, 116, 145))
	block.Material = Enum.Material.ForceField
	block.Transparency = 0.35
	block:SetAttribute("Hint", "Crouch")
	CollectionService:AddTag(block, "LowTunnelBlock")
	return block
end

local function updateLowTunnelBlocksForPlayer(player)
	local isCrouching = crouchingPlayers[player] == true
	local changedBlocks = 0

	for _, block in ipairs(CollectionService:GetTagged("LowTunnelBlock")) do
		if block:IsA("BasePart") then
			block.CanCollide = not isCrouching
			changedBlocks += 1
		end
	end

	debugCrouch(string.format(
		"player=%s crouching=%s blocks=%d",
		player.Name,
		tostring(isCrouching),
		changedBlocks
	))
end

local function createHazardCourseStage(parent, stage)
	local folder = Instance.new("Folder")
	folder.Name = stage.id
	folder.Parent = parent

	createPart(folder, "Floor", Vector3.new(32, 1, 102), stage.basePosition + Vector3.new(0, 0, 8), COLORS.Floor)
	createPart(folder, "LeftWall", Vector3.new(1, 8, 102), stage.basePosition + Vector3.new(-16.5, 4, 8), COLORS.Wall)
	createPart(folder, "RightWall", Vector3.new(1, 8, 102), stage.basePosition + Vector3.new(16.5, 4, 8), COLORS.Wall)
	createStageMarker(folder, stage, stage.basePosition + Vector3.new(0, 0.6, -35))

	createCheckpoint(folder, stage, "StartCheckpoint", stage.basePosition + Vector3.new(0, 0.85, -32))
	createCheckpoint(folder, stage, "MidCheckpoint", stage.basePosition + Vector3.new(0, 0.85, 22))

	createHazard(folder, stage, "HazardLeft1", Vector3.new(8, 0.35, 7), stage.basePosition + Vector3.new(-7, 0.9, -14))
	createHazard(folder, stage, "HazardRight1", Vector3.new(8, 0.35, 7), stage.basePosition + Vector3.new(7, 0.9, 0))
	createHazard(folder, stage, "HazardCenter1", Vector3.new(9, 0.35, 6), stage.basePosition + Vector3.new(0, 0.9, 38))
	createHazard(folder, stage, "HazardLeft2", Vector3.new(8, 0.35, 7), stage.basePosition + Vector3.new(-7, 0.9, 58))
	createHazard(folder, stage, "HazardRight2", Vector3.new(8, 0.35, 7), stage.basePosition + Vector3.new(7, 0.9, 72))

	for index = 1, 5 do
		createArrowGuide(folder, "SafeGuide" .. index, stage.basePosition + Vector3.new(0, 0.7, -33 + index * 18), COLORS.Accent)
	end

	local goal = createPart(folder, "GoalZone", Vector3.new(14, 1.5, 8), stage.goalPosition, COLORS.Goal)
	goal.Material = Enum.Material.Neon
	goal.Transparency = 0.15
	goal:SetAttribute("StageId", stage.id)
	CollectionService:AddTag(goal, "GoalZone")

	goal.Touched:Connect(function(hit)
		local player = getPlayerFromTouchedPart(hit)
		if not player then
			return
		end

		local state = playerStates[player]
		if state and state.stageId == stage.id then
			completeStage(player, stage)
		end
	end)
end

local function createSprintCourseStage(parent, stage)
	local folder = Instance.new("Folder")
	folder.Name = stage.id
	folder.Parent = parent

	createPart(folder, "Floor", Vector3.new(24, 1, 142), stage.basePosition + Vector3.new(0, 0, 8), COLORS.Floor)
	createPart(folder, "LeftWall", Vector3.new(1, 8, 142), stage.basePosition + Vector3.new(-12.5, 4, 8), COLORS.Wall)
	createPart(folder, "RightWall", Vector3.new(1, 8, 142), stage.basePosition + Vector3.new(12.5, 4, 8), COLORS.Wall)
	createStageMarker(folder, stage, stage.basePosition + Vector3.new(0, 0.6, -55))

	for index = 1, 7 do
		createArrowGuide(folder, "SprintGuide" .. index, stage.basePosition + Vector3.new(0, 0.7, -46 + index * 18), COLORS.Accent)
	end

	local midwayLabel = createFloorLabel(folder, "ShiftHint", stage.basePosition + Vector3.new(0, 0.6, -40), "SHIFT + W")
	midwayLabel.Size = Vector3.new(18, 0.1, 5)

	local goal = createPart(folder, "GoalZone", Vector3.new(14, 1.5, 8), stage.goalPosition, COLORS.Goal)
	goal.Material = Enum.Material.Neon
	goal.Transparency = 0.15
	goal:SetAttribute("StageId", stage.id)
	CollectionService:AddTag(goal, "GoalZone")

	goal.Touched:Connect(function(hit)
		local player = getPlayerFromTouchedPart(hit)
		if not player then
			return
		end

		local state = playerStates[player]
		if state and state.stageId == stage.id then
			completeStage(player, stage)
		end
	end)
end

local function createCrouchCourseStage(parent, stage)
	local folder = Instance.new("Folder")
	folder.Name = stage.id
	folder.Parent = parent

	createPart(folder, "Floor", Vector3.new(30, 1, 102), stage.basePosition + Vector3.new(0, 0, 2), COLORS.Floor)
	createPart(folder, "LeftWall", Vector3.new(1, 8, 102), stage.basePosition + Vector3.new(-15.5, 4, 2), COLORS.Wall)
	createPart(folder, "RightWall", Vector3.new(1, 8, 102), stage.basePosition + Vector3.new(15.5, 4, 2), COLORS.Wall)
	createStageMarker(folder, stage, stage.basePosition + Vector3.new(0, 0.6, -39))

	local tunnelFloor = createPart(folder, "TunnelFloor", Vector3.new(18, 0.25, 40), stage.basePosition + Vector3.new(0, 0.75, 5), Color3.fromRGB(47, 55, 66))
	tunnelFloor.Material = Enum.Material.SmoothPlastic

	local tunnelRoof = createPart(folder, "TunnelRoof", Vector3.new(18, 1, 40), stage.basePosition + Vector3.new(0, 7.2, 5), COLORS.Wall)
	tunnelRoof.Material = Enum.Material.SmoothPlastic

	createPart(folder, "TunnelLeftWall", Vector3.new(1, 6.5, 40), stage.basePosition + Vector3.new(-9.5, 3.8, 5), COLORS.Wall)
	createPart(folder, "TunnelRightWall", Vector3.new(1, 6.5, 40), stage.basePosition + Vector3.new(9.5, 3.8, 5), COLORS.Wall)
	createPart(folder, "TunnelBackTop", Vector3.new(18, 1, 2), stage.basePosition + Vector3.new(0, 7.2, 26), COLORS.Wall)
	createPart(folder, "TunnelBackWall", Vector3.new(18, 6.5, 1), stage.basePosition + Vector3.new(0, 3.8, 28), COLORS.Wall)

	createLowTunnelBlock(folder, "CrouchGateEntrance", Vector3.new(14, 5, 2), stage.basePosition + Vector3.new(0, 3.25, -15))
	createLowTunnelBlock(folder, "CrouchGateMiddle", Vector3.new(14, 5, 2), stage.basePosition + Vector3.new(0, 3.25, 5))

	local ctrlLabel = createFloorLabel(folder, "CtrlHint", stage.basePosition + Vector3.new(0, 0.6, -24), "CTRL")
	ctrlLabel.Size = Vector3.new(18, 0.1, 5)
	local lowLabel = createFloorLabel(folder, "LowHint", stage.basePosition + Vector3.new(0, 0.6, -10), "LOW ENTRY")
	lowLabel.Size = Vector3.new(14, 0.1, 5)

	for index = 1, 4 do
		createArrowGuide(folder, "CrouchGuide" .. index, stage.basePosition + Vector3.new(0, 0.95, -27 + index * 14), COLORS.Accent)
	end

	local goal = createPart(folder, "GoalZone", Vector3.new(12, 1.5, 7), stage.basePosition + Vector3.new(0, 1.2, 20), COLORS.Goal)
	goal.Material = Enum.Material.Neon
	goal.Transparency = 0.15
	goal:SetAttribute("StageId", stage.id)
	CollectionService:AddTag(goal, "GoalZone")

	goal.Touched:Connect(function(hit)
		local player = getPlayerFromTouchedPart(hit)
		if not player then
			return
		end

		local state = playerStates[player]
		if state and state.stageId == stage.id then
			completeStage(player, stage)
		end
	end)
end

local function createSprintStopTargetStage(parent, stage)
	local folder = Instance.new("Folder")
	folder.Name = stage.id
	folder.Parent = parent

	createPart(folder, "Floor", Vector3.new(34, 1, 174), stage.basePosition + Vector3.new(0, 0, 10), COLORS.Floor)
	createPart(folder, "LeftWall", Vector3.new(1, 8, 174), stage.basePosition + Vector3.new(-17.5, 4, 10), COLORS.Wall)
	createPart(folder, "RightWall", Vector3.new(1, 8, 174), stage.basePosition + Vector3.new(17.5, 4, 10), COLORS.Wall)
	createPart(folder, "TargetWall", Vector3.new(34, 16, 1), stage.basePosition + Vector3.new(0, 8, 78), COLORS.Wall)
	createStageMarker(folder, stage, stage.basePosition + Vector3.new(0, 0.6, -70))

	for index = 1, 7 do
		createArrowGuide(folder, "SprintGuide" .. index, stage.basePosition + Vector3.new(0, 0.7, -60 + index * 20), COLORS.Accent)
	end

	local stopPad = createPart(folder, "StopPad", Vector3.new(18, 0.35, 10), stage.basePosition + Vector3.new(0, 0.85, 48), Color3.fromRGB(80, 150, 230))
	stopPad.Material = Enum.Material.Neon
	stopPad:SetAttribute("Hint", "Stop and aim")
	stopPad.Touched:Connect(function(hit)
		local player = getPlayerFromTouchedPart(hit)
		if not player then
			return
		end

		local state = playerStates[player]
		if not state or state.stageId ~= stage.id or state.stopReached then
			return
		end

		state.stopReached = true
		revealStageTargets(folder)
		remotes.StageEvent:FireClient(player, "StageProgress", {
			id = stage.id,
			progressText = string.format("0 / %d", stage.targetCount),
		})
	end)

	local stopLabel = createFloorLabel(folder, "StopHint", stage.basePosition + Vector3.new(0, 0.6, 38), "STOP")
	stopLabel.Size = Vector3.new(16, 0.1, 5)

	local targetZ = stage.basePosition.Z + 77.4
	local targetPositions = {
		Vector3.new(stage.basePosition.X - 9, 6, targetZ),
		Vector3.new(stage.basePosition.X, 10, targetZ),
		Vector3.new(stage.basePosition.X + 9, 6, targetZ),
	}

	for targetId, position in ipairs(targetPositions) do
		createTarget(folder, stage, targetId, position)
	end
end

local function createJumpTargetStage(parent, stage)
	local folder = Instance.new("Folder")
	folder.Name = stage.id
	folder.Parent = parent

	createPart(folder, "StartFloor", Vector3.new(28, 1, 26), stage.basePosition + Vector3.new(0, 0, -30), COLORS.Floor)
	createPart(folder, "TargetFloor", Vector3.new(28, 1, 26), stage.basePosition + Vector3.new(0, 0, 42), COLORS.Floor)
	createPart(folder, "LeftWall", Vector3.new(1, 8, 104), stage.basePosition + Vector3.new(-14.5, 4, 4), COLORS.Wall)
	createPart(folder, "RightWall", Vector3.new(1, 8, 104), stage.basePosition + Vector3.new(14.5, 4, 4), COLORS.Wall)
	createPart(folder, "TargetWall", Vector3.new(28, 16, 1), stage.basePosition + Vector3.new(0, 8, 54), COLORS.Wall)
	createStageMarker(folder, stage, stage.basePosition + Vector3.new(0, 0.6, -40))

	local platformColor = Color3.fromRGB(92, 103, 116)
	local platformPositions = {
		Vector3.new(0, 1.5, -12),
		Vector3.new(0, 2.2, 5),
		Vector3.new(0, 2.8, 22),
	}

	for index, offset in ipairs(platformPositions) do
		createPart(folder, "JumpPlatform" .. index, Vector3.new(18, 2.2, 8), stage.basePosition + offset, platformColor)
		createArrowGuide(folder, "JumpTargetGuide" .. index, stage.basePosition + Vector3.new(0, offset.Y + 1.25, offset.Z - 1), COLORS.Accent)
	end

	local targetRevealPad = createPart(folder, "TargetRevealPad", Vector3.new(18, 0.35, 8), stage.basePosition + Vector3.new(0, 3.95, 22), Color3.fromRGB(80, 150, 230))
	targetRevealPad.Material = Enum.Material.Neon
	targetRevealPad.Transparency = 0.1
	targetRevealPad:SetAttribute("Hint", "Reveal targets")
	targetRevealPad.Touched:Connect(function(hit)
		local player = getPlayerFromTouchedPart(hit)
		if not player then
			return
		end

		local state = playerStates[player]
		if not state or state.stageId ~= stage.id or state.jumpTargetReady then
			return
		end

		state.jumpTargetReady = true
		revealStageTargets(folder)
		remotes.StageEvent:FireClient(player, "StageProgress", {
			id = stage.id,
			progressText = string.format("0 / %d", stage.targetCount),
		})
	end)

	local resetZone = createPart(folder, "FallReset", Vector3.new(32, 1, 104), stage.basePosition + Vector3.new(0, -8, 4), Color3.fromRGB(30, 34, 40))
	resetZone.Transparency = 1
	resetZone.CanCollide = false
	resetZone.Touched:Connect(function(hit)
		local player = getPlayerFromTouchedPart(hit)
		if not player then
			return
		end

		local state = playerStates[player]
		if state and state.stageId == stage.id then
			teleportPlayerToPosition(player, stage.spawnPosition)
		end
	end)

	local targetZ = stage.basePosition.Z + 53.4
	local targetPositions = {
		Vector3.new(stage.basePosition.X - 8, 6, targetZ),
		Vector3.new(stage.basePosition.X, 10, targetZ),
		Vector3.new(stage.basePosition.X + 8, 6, targetZ),
	}

	for targetId, position in ipairs(targetPositions) do
		createTarget(folder, stage, targetId, position)
	end
end

local function createArenaRobot(parent, stage, robotId, position, travelOffset)
	local robot = createPart(parent, "Robot_" .. robotId, Vector3.new(4, 4, 4), position, Color3.fromRGB(88, 170, 220))
	robot.Shape = Enum.PartType.Ball
	robot.Material = Enum.Material.SmoothPlastic
	robot.CanCollide = false
	robot:SetAttribute("StageId", stage.id)
	robot:SetAttribute("TargetId", robotId)
	robot:SetAttribute("Destroyed", false)
	CollectionService:AddTag(robot, "TrainingTarget")

	local light = Instance.new("PointLight")
	light.Name = "RobotLight"
	light.Brightness = 0.6
	light.Color = Color3.fromRGB(110, 210, 255)
	light.Range = 10
	light.Parent = robot

	local clickDetector = Instance.new("ClickDetector")
	clickDetector.MaxActivationDistance = 90
	clickDetector.Parent = robot

	local startPosition = position
	local endPosition = position + travelOffset
	local moveDuration = 3 + robotId * 0.45
	task.spawn(function()
		while robot.Parent do
			if robot:GetAttribute("Destroyed") then
				task.wait(0.1)
			else
				local alpha = (math.sin(os.clock() / moveDuration * math.pi * 2) + 1) / 2
				robot.Position = startPosition:Lerp(endPosition, alpha)
				task.wait(0.03)
			end
		end
	end)

	clickDetector.MouseClick:Connect(function(player)
		local state = playerStates[player]
		if not state or state.stageId ~= stage.id then
			return
		end

		clickedTargetsByPlayer[player] = clickedTargetsByPlayer[player] or {}
		if clickedTargetsByPlayer[player][robotId] then
			return
		end

		clickedTargetsByPlayer[player][robotId] = true
		state.hitCount += 1

		robot:SetAttribute("Destroyed", true)
		robot.Transparency = 1
		clickDetector.MaxActivationDistance = 0

		remotes.StageEvent:FireClient(player, "TargetHit", {
			target = robot,
			hitCount = state.hitCount,
			targetCount = stage.targetCount,
		})

		remotes.StageEvent:FireClient(player, "StageProgress", {
			id = stage.id,
			progressText = string.format("%d / %d", state.hitCount, stage.targetCount),
		})

		if state.hitCount >= stage.targetCount then
			state.arenaComplete = true
			local goal = parent:FindFirstChild("GoalZone")
			if goal and goal:IsA("BasePart") then
				goal.Transparency = 0.15
				goal.CanTouch = true
			end
			remotes.StageEvent:FireClient(player, "StageProgress", {
				id = stage.id,
				progressKey = "progress.goToExit",
			})
		end
	end)
end

local function createTrainingArenaStage(parent, stage)
	local folder = Instance.new("Folder")
	folder.Name = stage.id
	folder.Parent = parent

	createPart(folder, "Floor", Vector3.new(70, 1, 112), stage.basePosition + Vector3.new(0, 0, 12), COLORS.Floor)
	createPart(folder, "LeftWall", Vector3.new(1, 10, 112), stage.basePosition + Vector3.new(-35.5, 5, 12), COLORS.Wall)
	createPart(folder, "RightWall", Vector3.new(1, 10, 112), stage.basePosition + Vector3.new(35.5, 5, 12), COLORS.Wall)
	createPart(folder, "BackWall", Vector3.new(70, 10, 1), stage.basePosition + Vector3.new(0, 5, 68), COLORS.Wall)
	createPart(folder, "StartWall", Vector3.new(70, 10, 1), stage.basePosition + Vector3.new(0, 5, -44), COLORS.Wall)
	createStageMarker(folder, stage, stage.basePosition + Vector3.new(0, 0.6, -34))

	for index = 1, 4 do
		createArrowGuide(folder, "ArenaGuide" .. index, stage.basePosition + Vector3.new(0, 0.7, -30 + index * 14), COLORS.Accent)
	end

	local obstacleColor = Color3.fromRGB(58, 66, 78)
	createPart(folder, "ObstacleLeftNear", Vector3.new(10, 5, 16), stage.basePosition + Vector3.new(-18, 2.75, -10), obstacleColor)
	createPart(folder, "ObstacleRightMid", Vector3.new(12, 5, 12), stage.basePosition + Vector3.new(18, 2.75, 12), obstacleColor)
	createPart(folder, "ObstacleCenterFar", Vector3.new(9, 5, 18), stage.basePosition + Vector3.new(0, 2.75, 34), obstacleColor)
	createPart(folder, "ObstacleLeftFar", Vector3.new(12, 5, 10), stage.basePosition + Vector3.new(-20, 2.75, 48), obstacleColor)
	createPart(folder, "ObstacleRightFar", Vector3.new(9, 5, 14), stage.basePosition + Vector3.new(22, 2.75, 54), obstacleColor)

	createArenaRobot(folder, stage, 1, stage.basePosition + Vector3.new(-7, 3.4, -22), Vector3.new(14, 0, 0))
	createArenaRobot(folder, stage, 2, stage.basePosition + Vector3.new(8, 3.4, 30), Vector3.new(12, 0, 0))
	createArenaRobot(folder, stage, 3, stage.basePosition + Vector3.new(16, 3.4, 52), Vector3.new(0, 0, -10))
	createArenaRobot(folder, stage, 4, stage.basePosition + Vector3.new(-24, 3.4, 24), Vector3.new(0, 0, 14))

	local goal = createPart(folder, "GoalZone", Vector3.new(12, 1.5, 7), stage.goalPosition, COLORS.Goal)
	goal.Material = Enum.Material.Neon
	goal.Transparency = 1
	goal.CanTouch = false
	goal:SetAttribute("StageId", stage.id)
	CollectionService:AddTag(goal, "GoalZone")

	goal.Touched:Connect(function(hit)
		local player = getPlayerFromTouchedPart(hit)
		if not player then
			return
		end

		local state = playerStates[player]
		if state and state.stageId == stage.id and state.arenaComplete then
			completeStage(player, stage)
		end
	end)
end

function StageService.GenerateMap()
	local existing = Workspace:FindFirstChild("GeneratedTrainingMap")
	if existing then
		existing:Destroy()
	end

	generatedMap = Instance.new("Folder")
	generatedMap.Name = "GeneratedTrainingMap"
	generatedMap.Parent = Workspace

	createLobby(generatedMap)

	for _, stageId in ipairs(stageDefinitions.Order) do
		local stage = stageDefinitions.GetStage(stageId)
		if stage.type == "goal" then
			createWalkStage(generatedMap, stage)
		elseif stage.type == "targets" then
			createTargetStage(generatedMap, stage)
		elseif stage.type == "jump_course" then
			createJumpCourseStage(generatedMap, stage)
		elseif stage.type == "moving_targets" then
			createMovingTargetStage(generatedMap, stage)
		elseif stage.type == "hazard_course" then
			createHazardCourseStage(generatedMap, stage)
		elseif stage.type == "sprint_course" then
			createSprintCourseStage(generatedMap, stage)
		elseif stage.type == "crouch_course" then
			createCrouchCourseStage(generatedMap, stage)
		elseif stage.type == "sprint_stop_targets" then
			createSprintStopTargetStage(generatedMap, stage)
		elseif stage.type == "jump_targets" then
			createJumpTargetStage(generatedMap, stage)
		elseif stage.type == "training_arena" then
			createTrainingArenaStage(generatedMap, stage)
		end
	end
end

local function onPlayerAdded(player)
	player.CharacterAdded:Connect(function()
		task.wait(0.2)
		local currentStage = stageDefinitions.GetFirstStage()
		if playerStates[player] then
			currentStage = stageDefinitions.GetStage(playerStates[player].stageId) or currentStage
		end
		startStage(player, currentStage)
	end)

	if player.Character then
		task.defer(function()
			local firstStage = stageDefinitions.GetFirstStage()
			startStage(player, firstStage)
		end)
	end
end

local function onPlayerRemoving(player)
	playerStates[player] = nil
	clickedTargetsByPlayer[player] = nil
	completedDebounce[player] = nil
	crouchingPlayers[player] = nil
end

function StageService.Init(nextStageDefinitions, nextRewardService, nextRemotes)
	stageDefinitions = nextStageDefinitions
	rewardService = nextRewardService
	remotes = nextRemotes

	StageService.GenerateMap()

	if remotes.StageSelectEvent then
		remotes.StageSelectEvent.OnServerEvent:Connect(function(player, stageId)
			if typeof(stageId) ~= "string" then
				return
			end

			local stage = stageDefinitions.GetStage(stageId)
			if stage then
				startStage(player, stage)
			end
		end)
	end

	if remotes.CrouchStateEvent then
		remotes.CrouchStateEvent.OnServerEvent:Connect(function(player, isCrouching)
			debugCrouch("received crouch state from " .. player.Name .. " = " .. tostring(isCrouching))
			crouchingPlayers[player] = isCrouching == true
			updateLowTunnelBlocksForPlayer(player)
		end)
	end

	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)

	for _, player in ipairs(Players:GetPlayers()) do
		onPlayerAdded(player)
	end
end

return StageService
