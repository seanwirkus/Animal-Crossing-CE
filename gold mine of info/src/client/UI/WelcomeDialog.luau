--[[
	WelcomeDialog - Shows welcome message for players without islands
	Appears automatically when player joins and has no island
	Directs them to Isabelle for island setup
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- local GUIComponents = require(ReplicatedStorage.GUIComponents) -- Disabled for now

local WelcomeDialog = {}
WelcomeDialog.__index = WelcomeDialog

function WelcomeDialog.new()
	local self = setmetatable({}, WelcomeDialog)

	self._player = Players.LocalPlayer
	self:_create()

	return self
end

function WelcomeDialog:_create()
	local playerGui = self._player:WaitForChild("PlayerGui")

	-- Main screen
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "WelcomeDialog"
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 15  -- Higher than other GUIs
	screenGui.IgnoreGuiInset = true  -- Use full screen
	screenGui.Parent = playerGui

	-- Semi-transparent backdrop
	local bg = Instance.new("Frame")
	bg.Name = "Background"
	bg.Size = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3 = Color3.new(0, 0, 0)
	bg.BackgroundTransparency = 0.3  -- More subtle
	bg.BorderSizePixel = 0
	bg.Parent = screenGui

	-- Create responsive main panel
	local panel, theme = GUIComponents.CreatePanel(bg, {
		name = "WelcomePanel",
		minWidth = 500,
		minHeight = 400
	})

	-- Welcome title
	GUIComponents.CreateTitle(panel, {
		text = "🏝️ Welcome to Your Island Adventure!",
		textSize = 28,
		theme = theme
	})

	-- Welcome message
	GUIComponents.CreateInfoText(panel, {
		text = "You've arrived at a beautiful tropical paradise! To start your island life, talk to Isabelle - she'll help you set up your very own personal island completely FREE OF CHARGE! 🎉\n\nLook for the friendly dog character near the spawn area!",
		position = 90,
		height = 120,
		textSize = 16,
		theme = theme
	})

	-- Continue button
	GUIComponents.CreateButton(panel, {
		text = "Got it! Let's find Isabelle!",
		position = 220,
		color = theme.successColor,
		theme = theme,
		callback = function()
			screenGui:Destroy()
		end
	})

	-- Auto-close after 15 seconds (in case they ignore it)
	task.delay(15, function()
		if screenGui and screenGui.Parent then
			screenGui:Destroy()
		end
	end)

	self._screenGui = screenGui

	-- Animate panel in
	local panelFrame = panel
	panelFrame.Position = UDim2.new(0.5, -panelFrame.AbsoluteSize.X / 2, 1.5, 0)
	local TweenService = game:GetService("TweenService")
	TweenService:Create(panelFrame, TweenInfo.new(0.8, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, -panelFrame.AbsoluteSize.X / 2, 0.5, -panelFrame.AbsoluteSize.Y / 2)
	}):Play()
end

function WelcomeDialog:Destroy()
	if self._screenGui then
		self._screenGui:Destroy()
	end
end

return WelcomeDialog
