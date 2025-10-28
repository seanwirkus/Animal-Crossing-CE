--[[
	PlayerController - Main client controller for Animal Crossing
	Handles player data, UI, and game state
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local Local = {}
local Shared = {}

-- Player data
local playerData = nil
local isOnboarding = false

-- UI References
local mainUI = nil
local onboardingUI = nil

function Local.CreateMainUI()
	if mainUI then return end
	
	-- Create main game UI
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "MainUI"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = PlayerGui
	
	-- Top bar for currency
	local topBar = Instance.new("Frame")
	topBar.Name = "TopBar"
	topBar.Size = UDim2.new(1, 0, 0, 60)
	topBar.Position = UDim2.new(0, 0, 0, 0)
	topBar.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	topBar.BackgroundTransparency = 0.3
	topBar.BorderSizePixel = 0
	topBar.Parent = screenGui
	
	-- Bells display
	local bellsFrame = Instance.new("Frame")
	bellsFrame.Name = "BellsFrame"
	bellsFrame.Size = UDim2.new(0, 120, 1, 0)
	bellsFrame.Position = UDim2.new(0, 10, 0, 0)
	bellsFrame.BackgroundTransparency = 1
	bellsFrame.Parent = topBar
	
	local bellsIcon = Instance.new("TextLabel")
	bellsIcon.Name = "BellsIcon"
	bellsIcon.Size = UDim2.new(0, 30, 1, 0)
	bellsIcon.Position = UDim2.new(0, 0, 0, 0)
	bellsIcon.BackgroundTransparency = 1
	bellsIcon.Text = "🔔"
	bellsIcon.TextColor3 = Color3.fromRGB(255, 255, 0)
	bellsIcon.TextScaled = true
	bellsIcon.Font = Enum.Font.GothamBold
	bellsIcon.Parent = bellsFrame
	
	local bellsLabel = Instance.new("TextLabel")
	bellsLabel.Name = "BellsLabel"
	bellsLabel.Size = UDim2.new(1, -40, 1, 0)
	bellsLabel.Position = UDim2.new(0, 35, 0, 0)
	bellsLabel.BackgroundTransparency = 1
	bellsLabel.Text = "1,000"
	bellsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	bellsLabel.TextScaled = true
	bellsLabel.Font = Enum.Font.GothamBold
	bellsLabel.TextXAlignment = Enum.TextXAlignment.Left
	bellsLabel.Parent = bellsFrame
	
	-- Miles display
	local milesFrame = Instance.new("Frame")
	milesFrame.Name = "MilesFrame"
	milesFrame.Size = UDim2.new(0, 120, 1, 0)
	milesFrame.Position = UDim2.new(0, 140, 0, 0)
	milesFrame.BackgroundTransparency = 1
	milesFrame.Parent = topBar
	
	local milesIcon = Instance.new("TextLabel")
	milesIcon.Name = "MilesIcon"
	milesIcon.Size = UDim2.new(0, 30, 1, 0)
	milesIcon.Position = UDim2.new(0, 0, 0, 0)
	milesIcon.BackgroundTransparency = 1
	milesIcon.Text = "✈️"
	milesIcon.TextColor3 = Color3.fromRGB(0, 150, 255)
	milesIcon.TextScaled = true
	milesIcon.Font = Enum.Font.GothamBold
	milesIcon.Parent = milesFrame
	
	local milesLabel = Instance.new("TextLabel")
	milesLabel.Name = "MilesLabel"
	milesLabel.Size = UDim2.new(1, -40, 1, 0)
	milesLabel.Position = UDim2.new(0, 35, 0, 0)
	milesLabel.BackgroundTransparency = 1
	milesLabel.Text = "500"
	milesLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	milesLabel.TextScaled = true
	milesLabel.Font = Enum.Font.GothamBold
	milesLabel.TextXAlignment = Enum.TextXAlignment.Left
	milesLabel.Parent = milesFrame
	
	-- Time display
	local timeLabel = Instance.new("TextLabel")
	timeLabel.Name = "TimeLabel"
	timeLabel.Size = UDim2.new(0, 150, 1, 0)
	timeLabel.Position = UDim2.new(1, -160, 0, 0)
	timeLabel.BackgroundTransparency = 1
	timeLabel.Text = "🕐 10:00 AM"
	timeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	timeLabel.TextScaled = true
	timeLabel.Font = Enum.Font.GothamBold
	timeLabel.Parent = topBar
	
	mainUI = screenGui
	print("[PlayerController] Main UI created")
end

function Local.CreateOnboardingUI()
	if onboardingUI then return end
	
	-- Create onboarding UI
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "OnboardingUI"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = PlayerGui
	
	-- Main frame
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(0, 500, 0, 400)
	mainFrame.Position = UDim2.new(0.5, -250, 0.5, -200)
	mainFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = screenGui
	
	-- Add corner rounding
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = mainFrame
	
	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 60)
	title.Position = UDim2.new(0, 0, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = "Welcome to Your Island!"
	title.TextColor3 = Color3.fromRGB(0, 0, 0)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.Parent = mainFrame
	
	-- Description
	local description = Instance.new("TextLabel")
	description.Name = "Description"
	description.Size = UDim2.new(1, -20, 0, 200)
	description.Position = UDim2.new(0, 10, 0, 70)
	description.BackgroundTransparency = 1
	description.Text = "Welcome to your new island! I'm Tom Nook, and I'll be helping you get settled. Let's start by choosing your perfect island paradise!"
	description.TextColor3 = Color3.fromRGB(0, 0, 0)
	description.TextWrapped = true
	description.Font = Enum.Font.Gotham
	description.Parent = mainFrame
	
	-- Continue button
	local continueButton = Instance.new("TextButton")
	continueButton.Name = "ContinueButton"
	continueButton.Size = UDim2.new(0, 120, 0, 40)
	continueButton.Position = UDim2.new(0.5, -60, 1, -60)
	continueButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
	continueButton.Text = "Continue"
	continueButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	continueButton.Font = Enum.Font.GothamBold
	continueButton.Parent = mainFrame
	
	-- Add corner rounding to button
	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 8)
	buttonCorner.Parent = continueButton
	
	-- Button click handler
	continueButton.MouseButton1Click:Connect(function()
		Local.CompleteOnboarding()
	end)
	
	onboardingUI = screenGui
	print("[PlayerController] Onboarding UI created")
end

function Local.CompleteOnboarding()
	print("[PlayerController] Completing onboarding...")
	
	if onboardingUI then
		onboardingUI:Destroy()
		onboardingUI = nil
	end
	
	isOnboarding = false
	
	-- Fire remote to server
	local remotes = ReplicatedStorage:WaitForChild("Remotes", 5)
	if remotes then
		local completeRemote = remotes:WaitForChild("CompleteOnboarding", 5)
		if completeRemote then
			completeRemote:FireServer()
		end
	end
end

function Local.UpdatePlayerData(data)
	playerData = data
	print("[PlayerController] Player data updated")
	
	-- Update UI with new data
	if mainUI then
		local bellsLabel = mainUI.TopBar.BellsFrame.BellsLabel
		local milesLabel = mainUI.TopBar.MilesFrame.MilesLabel
		
		if bellsLabel and data.balance then
			bellsLabel.Text = tostring(data.balance.bells)
		end
		
		if milesLabel and data.balance then
			milesLabel.Text = tostring(data.balance.miles)
		end
	end
end

function Shared.OnStart()
	print("[PlayerController] Starting Animal Crossing PlayerController...")
	
	-- Create main UI
	Local.CreateMainUI()
	
	-- Connect to remotes
	local remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
	if remotes then
		-- Player data loaded
		local playerDataRemote = remotes:WaitForChild("PlayerDataLoaded", 5)
		if playerDataRemote then
			playerDataRemote.OnClientEvent:Connect(Local.UpdatePlayerData)
		end
		
		-- Start onboarding
		local startOnboardingRemote = remotes:WaitForChild("StartOnboarding", 5)
		if startOnboardingRemote then
			startOnboardingRemote.OnClientEvent:Connect(function()
				print("[PlayerController] Starting onboarding...")
				isOnboarding = true
				Local.CreateOnboardingUI()
			end)
		end
	end
	
	-- Handle input
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		
		if input.KeyCode == Enum.KeyCode.E then
			-- Interact with nearby NPCs
			print("[PlayerController] E key pressed - looking for NPCs...")
		end
	end)
end

return Shared
