--[[
	IslandManagementGUI - SIMPLIFIED VERSION THAT ACTUALLY WORKS
	Just shows a delete button and basic info
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local IslandManagementGUI = {}
IslandManagementGUI.__index = IslandManagementGUI

function IslandManagementGUI.new(islandData)
	local self = setmetatable({}, IslandManagementGUI)
	self._player = Players.LocalPlayer
	self._islandData = islandData or {}
	self:_create()
	return self
end

function IslandManagementGUI:_create()
	local playerGui = self._player:WaitForChild("PlayerGui")

	-- Main screen GUI
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "IslandManagementGUI"
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 100
	screenGui.IgnoreGuiInset = true
	screenGui.Parent = playerGui

	-- Semi-transparent backdrop
	local backdrop = Instance.new("Frame")
	backdrop.Name = "Backdrop"
	backdrop.Size = UDim2.new(1, 0, 1, 0)
	backdrop.BackgroundColor3 = Color3.new(0, 0, 0)
	backdrop.BackgroundTransparency = 0.5
	backdrop.BorderSizePixel = 0
	backdrop.Parent = screenGui
	
	-- Main panel (HUGE, VISIBLE, SIMPLE)
	local panel = Instance.new("Frame")
	panel.Name = "MainPanel"
	panel.Size = UDim2.new(0, 600, 0, 500)
	panel.Position = UDim2.new(0.5, -300, 0.5, -250)
	panel.BackgroundColor3 = Color3.fromRGB(250, 250, 250)
	panel.BorderSizePixel = 5
	panel.BorderColor3 = Color3.fromRGB(0, 0, 0)
	panel.Parent = backdrop
	
	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 80)
	title.Position = UDim2.new(0, 0, 0, 0)
	title.BackgroundColor3 = Color3.fromRGB(76, 175, 80)
	title.BorderSizePixel = 0
	title.Text = "🏝️ Island Management"
	title.TextSize = 32
	title.Font = Enum.Font.GothamBold
	title.TextColor3 = Color3.new(1, 1, 1)
	title.Parent = panel
	
	-- Island name
	local islandName = Instance.new("TextLabel")
	islandName.Name = "IslandName"
	islandName.Size = UDim2.new(1, -40, 0, 60)
	islandName.Position = UDim2.new(0, 20, 0, 100)
	islandName.BackgroundTransparency = 1
	islandName.Text = "📍 " .. (self._islandData.islandName or "Your Island")
	islandName.TextSize = 24
	islandName.Font = Enum.Font.Gotham
	islandName.TextColor3 = Color3.fromRGB(40, 40, 40)
	islandName.TextXAlignment = Enum.TextXAlignment.Left
	islandName.Parent = panel
	
	-- Management Buttons
	local y = 180

	-- Upgrade Home button
	local upgradeButton = Instance.new("TextButton")
	upgradeButton.Name = "UpgradeButton"
	upgradeButton.Size = UDim2.new(0, 500, 0, 60)
	upgradeButton.Position = UDim2.new(0.5, -250, 0, y)
	upgradeButton.BackgroundColor3 = Color3.fromRGB(33, 150, 243)
	upgradeButton.BorderSizePixel = 3
	upgradeButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
	upgradeButton.Text = "🏠 Upgrade Home"
	upgradeButton.TextSize = 24
	upgradeButton.Font = Enum.Font.GothamBold
	upgradeButton.TextColor3 = Color3.new(1, 1, 1)
	upgradeButton.Parent = panel

	if self._islandData.homeUpgraded then
		upgradeButton.Text = "🏠 Home Fully Upgraded"
		upgradeButton.BackgroundColor3 = Color3.fromRGB(180, 180, 180)
		upgradeButton.AutoButtonColor = false
		upgradeButton.Active = false
	else
		upgradeButton.MouseButton1Click:Connect(function()
			print("[IslandManagementGUI] Upgrade home clicked!")
			local RemotesFolder = ReplicatedStorage:WaitForChild("Remotes")
			local upgradeRemote = RemotesFolder:FindFirstChild("UpgradeHome")
			if upgradeRemote then
				upgradeRemote:FireServer()
				upgradeButton.Text = "🏠 Home Fully Upgraded"
				upgradeButton.BackgroundColor3 = Color3.fromRGB(180, 180, 180)
				upgradeButton.AutoButtonColor = false
				upgradeButton.Active = false
			else
				warn("[IslandManagementGUI] UpgradeHome remote not found!")
			end
		end)
	end

	y = y + 70
	-- Rename Island button
	local renameButton = Instance.new("TextButton")
	renameButton.Name = "RenameButton"
	renameButton.Size = UDim2.new(0, 500, 0, 60)
	renameButton.Position = UDim2.new(0.5, -250, 0, y)
	renameButton.BackgroundColor3 = Color3.fromRGB(255, 193, 7)
	renameButton.BorderSizePixel = 3
	renameButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
	renameButton.Text = "✏️ Rename Island"
	renameButton.TextSize = 24
	renameButton.Font = Enum.Font.GothamBold
	renameButton.TextColor3 = Color3.new(1, 1, 1)
	renameButton.Parent = panel

	renameButton.MouseButton1Click:Connect(function()
		local RemotesFolder = ReplicatedStorage:WaitForChild("Remotes")
		local renameRemote = RemotesFolder:FindFirstChild("RenameIsland")
		if renameRemote then
			local newName = "My New Island" -- TODO: Show input dialog for user
			renameRemote:FireServer(newName)
			islandName.Text = "📍 " .. newName
		else
			warn("[IslandManagementGUI] RenameIsland remote not found!")
		end
	end)

	y = y + 70
	-- Invite Friend button
	local inviteButton = Instance.new("TextButton")
	inviteButton.Name = "InviteButton"
	inviteButton.Size = UDim2.new(0, 500, 0, 60)
	inviteButton.Position = UDim2.new(0.5, -250, 0, y)
	inviteButton.BackgroundColor3 = Color3.fromRGB(76, 175, 80)
	inviteButton.BorderSizePixel = 3
	inviteButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
	inviteButton.Text = "👫 Invite Friend"
	inviteButton.TextSize = 24
	inviteButton.Font = Enum.Font.GothamBold
	inviteButton.TextColor3 = Color3.new(1, 1, 1)
	inviteButton.Parent = panel

	inviteButton.MouseButton1Click:Connect(function()
		local RemotesFolder = ReplicatedStorage:WaitForChild("Remotes")
		local inviteRemote = RemotesFolder:FindFirstChild("InviteFriendToIsland")
		if inviteRemote then
			local friendName = "FriendName" -- TODO: Show input dialog for user
			inviteRemote:FireServer(friendName)
		else
			warn("[IslandManagementGUI] InviteFriendToIsland remote not found!")
		end
	end)

	y = y + 70
	-- View Residents button
	local residentsButton = Instance.new("TextButton")
	residentsButton.Name = "ResidentsButton"
	residentsButton.Size = UDim2.new(0, 500, 0, 60)
	residentsButton.Position = UDim2.new(0.5, -250, 0, y)
	residentsButton.BackgroundColor3 = Color3.fromRGB(156, 39, 176)
	residentsButton.BorderSizePixel = 3
	residentsButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
	residentsButton.Text = "👥 View Residents"
	residentsButton.TextSize = 24
	residentsButton.Font = Enum.Font.GothamBold
	residentsButton.TextColor3 = Color3.new(1, 1, 1)
	residentsButton.Parent = panel

	residentsButton.MouseButton1Click:Connect(function()
		local RemotesFolder = ReplicatedStorage:WaitForChild("Remotes")
		local residentsRemote = RemotesFolder:FindFirstChild("GetIslandResidents")
		if residentsRemote then
			residentsRemote:FireServer()
			-- TODO: Show residents list in a popup
		else
			warn("[IslandManagementGUI] GetIslandResidents remote not found!")
		end
	end)

	y = y + 70
	-- BIG DELETE BUTTON
	local deleteButton = Instance.new("TextButton")
	deleteButton.Name = "DeleteButton"
	deleteButton.Size = UDim2.new(0, 500, 0, 80)
	deleteButton.Position = UDim2.new(0.5, -250, 0, y)
	deleteButton.BackgroundColor3 = Color3.fromRGB(244, 67, 54)
	deleteButton.BorderSizePixel = 3
	deleteButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
	deleteButton.Text = "🗑️ DELETE ISLAND\n& START FRESH"
	deleteButton.TextSize = 28
	deleteButton.Font = Enum.Font.GothamBold
	deleteButton.TextColor3 = Color3.new(1, 1, 1)
	deleteButton.Parent = panel

	deleteButton.MouseButton1Click:Connect(function()
		print("[IslandManagementGUI] Delete island clicked!")
		local RemotesFolder = ReplicatedStorage:WaitForChild("Remotes")
		local deleteRemote = RemotesFolder:FindFirstChild("DeletePlayerIsland")
		if deleteRemote then
			deleteRemote:FireServer()
			print("[IslandManagementGUI] Delete request sent to server")
			screenGui:Destroy()
			task.wait(1)
			Players.LocalPlayer:Kick("✅ Island deleted! Press F5 to create a new island!")
		else
			warn("[IslandManagementGUI] DeletePlayerIsland remote not found!")
		end
	end)

	y = y + 90
	-- Close button
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0, 500, 0, 60)
	closeButton.Position = UDim2.new(0.5, -250, 0, y)
	closeButton.BackgroundColor3 = Color3.fromRGB(120, 120, 120)
	closeButton.BorderSizePixel = 3
	closeButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
	closeButton.Text = "✕ Close"
	closeButton.TextSize = 24
	closeButton.Font = Enum.Font.GothamBold
	closeButton.TextColor3 = Color3.new(1, 1, 1)
	closeButton.Parent = panel

	closeButton.MouseButton1Click:Connect(function()
		screenGui:Destroy()
	end)

	y = y + 70
	-- Info text
	local infoText = Instance.new("TextLabel")
	infoText.Name = "InfoText"
	infoText.Size = UDim2.new(1, -40, 0, 80)
	infoText.Position = UDim2.new(0, 20, 0, y)
	infoText.BackgroundTransparency = 1
	infoText.Text = "Manage your island: upgrade, rename, invite friends, view residents, or delete to start fresh!"
	infoText.TextSize = 16
	infoText.Font = Enum.Font.Gotham
	infoText.TextColor3 = Color3.fromRGB(100, 100, 100)
	infoText.TextXAlignment = Enum.TextXAlignment.Center
	infoText.TextWrapped = true
	infoText.Parent = panel

	print("[IslandManagementGUI] ✅ Management GUI created successfully")
end

return IslandManagementGUI
