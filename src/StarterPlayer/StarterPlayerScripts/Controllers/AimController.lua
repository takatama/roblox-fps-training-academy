local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AimController = {}

local player = Players.LocalPlayer
local config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local function createLine(parent, name, size, position)
	local line = Instance.new("Frame")
	line.Name = name
	line.AnchorPoint = Vector2.new(0.5, 0.5)
	line.BackgroundColor3 = config.CrosshairColor
	line.BorderSizePixel = 0
	line.Position = position
	line.Size = size
	line.Parent = parent
	return line
end

function AimController.Init()
	local playerGui = player:WaitForChild("PlayerGui")
	local gui = playerGui:FindFirstChild("AimGuiRuntime")
	if gui then
		return
	end

	gui = Instance.new("ScreenGui")
	gui.Name = "AimGuiRuntime"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.Parent = playerGui

	local root = Instance.new("Frame")
	root.Name = "Crosshair"
	root.AnchorPoint = Vector2.new(0.5, 0.5)
	root.BackgroundTransparency = 1
	root.Position = UDim2.fromScale(0.5, 0.5)
	root.Size = UDim2.fromOffset(34, 34)
	root.Parent = gui

	createLine(root, "Top", UDim2.fromOffset(2, 9), UDim2.fromScale(0.5, 0.22))
	createLine(root, "Bottom", UDim2.fromOffset(2, 9), UDim2.fromScale(0.5, 0.78))
	createLine(root, "Left", UDim2.fromOffset(9, 2), UDim2.fromScale(0.22, 0.5))
	createLine(root, "Right", UDim2.fromOffset(9, 2), UDim2.fromScale(0.78, 0.5))

	local dot = Instance.new("Frame")
	dot.Name = "Dot"
	dot.AnchorPoint = Vector2.new(0.5, 0.5)
	dot.BackgroundColor3 = config.CrosshairAccentColor
	dot.BorderSizePixel = 0
	dot.Position = UDim2.fromScale(0.5, 0.5)
	dot.Size = UDim2.fromOffset(4, 4)
	dot.Parent = root
end

return AimController
