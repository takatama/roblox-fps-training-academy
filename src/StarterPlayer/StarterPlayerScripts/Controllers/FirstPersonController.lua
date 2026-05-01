local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local FirstPersonController = {}

local player = Players.LocalPlayer

local function applyFirstPerson()
	if player:GetAttribute("StageMenuOpen") then
		player.CameraMode = Enum.CameraMode.Classic
		player.CameraMinZoomDistance = 0.5
		player.CameraMaxZoomDistance = 12
		Workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
		return
	end

	player.CameraMode = Enum.CameraMode.LockFirstPerson
	player.CameraMinZoomDistance = 0.5
	player.CameraMaxZoomDistance = 0.5
	Workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	UserInputService.MouseIconEnabled = false
end

function FirstPersonController.Init()
	applyFirstPerson()

	player.CharacterAdded:Connect(function()
		task.wait(0.1)
		applyFirstPerson()
	end)

	player:GetAttributeChangedSignal("StageMenuOpen"):Connect(applyFirstPerson)
	UserInputService.WindowFocused:Connect(applyFirstPerson)
end

return FirstPersonController
