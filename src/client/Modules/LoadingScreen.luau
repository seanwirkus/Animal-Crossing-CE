--[[
	LoadingScreen.luau
	
	Animal Crossing-style loading screen with character preview and asset preloading.
	Used for initial game load with "Start Game" button.
	
	Features:
	- Character preview in viewport (player's avatar)
	- Asset preloading with progress bar
	- Random loading tips (ACNH style)
	- Fade in/out transitions
	- Start game button when ready
	
	Usage:
		local LoadingScreen = require(path.to.LoadingScreen)
		
		-- Initialize and show
		LoadingScreen.init()
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ContentProvider = game:GetService("ContentProvider")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local LoadingScreen = {}
LoadingScreen.isLoading = true  -- Exposed property for checking load status

-- Orientation helper: yaw to face the plane to screen-right in the viewport
local _YAW_TO_FACE_RIGHT = math.rad(90)

-- Loading tips (ACNH style)
local LOADING_TIPS = {
	"Did you know? You can shake trees to find furniture!",
	"Tip: Talk to villagers every day to build friendship.",
	"Catching bugs is easier when you walk slowly!",
	"Pro tip: Fish shadows show their size. Bigger shadow = bigger fish!",
	"Don't forget to check Nook's Cranny for new items daily!",
	"Balloons often carry furniture and DIY recipes!",
	"Tip: Plant fruit trees to grow bells!",
	"Did you know? Different fish appear at different times.",
	"Fossils can be found by digging X-marks on the ground!",
	"Tip: Donate bugs and fish to Blathers for the museum!",
	"Pro tip: Save your game regularly at the tent!",
	"Did you know? You can customize some furniture items!",
	"Tip: Nook Miles can be earned by completing daily tasks!",
	"Press E to open your inventory!",
	"Tip: Golden tools are more durable than regular ones!",
	"Did you know? You can catch snowflakes in winter!",
	"Pro tip: Plant flowers to attract rare bugs!",
	"Tip: Check the beach for message bottles with DIY recipes!",
	"Did you know? Turnip prices change twice daily!",
	"Tip: Visit other players' islands for new items!",
}

-- Assets to preload
local ASSETS_TO_PRELOAD = {
	"rbxassetid://79857338226248",  -- Sprite sheet
	"rbxassetid://98139431900134",  -- Hole model
	-- Add more asset IDs as needed
}

-- State
local _gui = nil
local _frame = nil
local _characterViewport = nil
local _tipLabel = nil
local _progressBar = nil
local _progressBarFill = nil
local _statusLabel = nil
local _startButton = nil
local _isShowing = false
local _isReady = false
local _settingsPanel = nil
local _applySettingsButton = nil
local _presetButtons: {TextButton}? = nil
local _selectedPreset: string = "Medium"
local _keybindsPanel = nil
local _continueButton = nil

-- Cached post effects (client-only, parented to CurrentCamera)
local _effects = {
	Bloom = nil :: BloomEffect?,
	SunRays = nil :: SunRaysEffect?,
	ColorCorrection = nil :: ColorCorrectionEffect?,
}

-- Utility: ensure we have a camera for client-side post effects
local function getCurrentCamera(): Camera
	return Workspace.CurrentCamera or Workspace:WaitForChild("Camera")
end

-- Create or fetch post effects on the client (non-replicated visual settings)
local function ensurePostEffects()
	local cam = getCurrentCamera()
	if not _effects.Bloom or not _effects.Bloom.Parent then
		local bloom = Instance.new("BloomEffect")
		bloom.Name = "ACCE_Bloom"
		bloom.Intensity = 0
		bloom.Size = 0
		bloom.Threshold = 1
		bloom.Enabled = false
		bloom.Parent = cam
		_effects.Bloom = bloom
	end
	if not _effects.SunRays or not _effects.SunRays.Parent then
		local sun = Instance.new("SunRaysEffect")
		sun.Name = "ACCE_SunRays"
		sun.Intensity = 0
		sun.Spread = 0.2
		sun.Enabled = false
		sun.Parent = cam
		_effects.SunRays = sun
	end
	if not _effects.ColorCorrection or not _effects.ColorCorrection.Parent then
		local cc = Instance.new("ColorCorrectionEffect")
		cc.Name = "ACCE_ColorCorrection"
		cc.Contrast = 0
		cc.Saturation = 0
		cc.Brightness = 0
		cc.Enabled = false
		cc.Parent = cam
		_effects.ColorCorrection = cc
	end
end

-- Apply a simple graphics preset. Low disables effects, Medium mild, High stronger.
local function applyGraphicsPreset(preset: string)
	_selectedPreset = preset
	ensurePostEffects()
	local bloom = _effects.Bloom :: BloomEffect
	local sun = _effects.SunRays :: SunRaysEffect
	local cc = _effects.ColorCorrection :: ColorCorrectionEffect

	if preset == "Low" then
		bloom.Enabled = false
		bloom.Intensity = 0
		bloom.Size = 0
		sun.Enabled = false
		sun.Intensity = 0
		cc.Enabled = false
		cc.Contrast = 0
		cc.Saturation = 0
		cc.Brightness = 0
	elseif preset == "High" then
		bloom.Enabled = true
		bloom.Intensity = 0.7
		bloom.Size = 24
		sun.Enabled = true
		sun.Intensity = 0.12
		cc.Enabled = true
		cc.Contrast = 0.06
		cc.Saturation = 0.08
		cc.Brightness = 0.02
	else -- Medium (default)
		bloom.Enabled = true
		bloom.Intensity = 0.4
		bloom.Size = 18
		sun.Enabled = true
		sun.Intensity = 0.06
		cc.Enabled = true
		cc.Contrast = 0.03
		cc.Saturation = 0.04
		cc.Brightness = 0.01
	end
end

--[[
	Pick a random loading tip
]]
local function getRandomTip(): string
	return LOADING_TIPS[math.random(1, #LOADING_TIPS)]
end

--[[
	Create the loading screen GUI
]]
local function createGUI()
	if _gui then return end
	
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")
	
	-- Main ScreenGui
	_gui = Instance.new("ScreenGui")
	_gui.Name = "LoadingScreen"
	_gui.DisplayOrder = 999 -- Below cutscene fade, above everything else
	_gui.ResetOnSpawn = false
	_gui.IgnoreGuiInset = true
	_gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	
	-- Background frame (sky blue like ACNH with enhanced gradient)
	_frame = Instance.new("Frame")
	_frame.Name = "LoadingFrame"
	_frame.Size = UDim2.new(1, 0, 1, 0)
	_frame.Position = UDim2.new(0, 0, 0, 0)
	_frame.BackgroundColor3 = Color3.fromRGB(135, 206, 235) -- Sky blue
	_frame.BackgroundTransparency = 0
	_frame.BorderSizePixel = 0
	_frame.Parent = _gui
	
	-- Enhanced gradient for depth with multiple colors
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(135, 206, 250)), -- Lighter sky blue
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(135, 206, 235)), -- Sky blue
		ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 180, 220)) -- Deeper blue
	})
	gradient.Rotation = 90
	gradient.Parent = _frame
	
	-- Decorative clouds (simple circles)
	for i = 1, 5 do
		local cloud = Instance.new("Frame")
		cloud.Name = "Cloud" .. i
		cloud.Size = UDim2.new(0, math.random(80, 150), 0, math.random(40, 70))
		cloud.Position = UDim2.new(math.random(0, 100) / 100, 0, math.random(5, 25) / 100, 0)
		cloud.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		cloud.BackgroundTransparency = 0.6
		cloud.BorderSizePixel = 0
		cloud.Parent = _frame
		
		local cloudCorner = Instance.new("UICorner")
		cloudCorner.CornerRadius = UDim.new(1, 0)
		cloudCorner.Parent = cloud
		
		-- Animate clouds slowly
		task.spawn(function()
			while cloud and cloud.Parent do
				local tween = TweenService:Create(cloud, TweenInfo.new(3 + math.random(), Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
					Position = cloud.Position + UDim2.new(0, math.random(-20, 20), 0, 0)
				})
				tween:Play()
				task.wait(3 + math.random())
			end
		end)
	end
	
	-- Title with enhanced styling
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(0, 700, 0, 90)
	titleLabel.Position = UDim2.new(0.5, -350, 0.06, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "Animal Crossing CE"
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextSize = 58
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.TextStrokeTransparency = 0.2
	titleLabel.TextStrokeColor3 = Color3.fromRGB(60, 120, 160)
	titleLabel.Parent = _frame
	
	-- Subtle pulsing animation for title
	task.spawn(function()
		while titleLabel and titleLabel.Parent do
			TweenService:Create(titleLabel, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
				TextSize = 60
			}):Play()
			task.wait(2)
		end
	end)
	
	-- Subtitle with better positioning
	local subtitleLabel = Instance.new("TextLabel")
	subtitleLabel.Name = "Subtitle"
	subtitleLabel.Size = UDim2.new(0, 450, 0, 35)
	subtitleLabel.Position = UDim2.new(0.5, -225, 0.14, 0)
	subtitleLabel.BackgroundTransparency = 1
	subtitleLabel.Text = "Community Edition"
	subtitleLabel.Font = Enum.Font.GothamBold
	subtitleLabel.TextSize = 22
	subtitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	subtitleLabel.TextTransparency = 0.2
	subtitleLabel.Parent = _frame
	
	-- Plane viewport (smaller and shifted to the right)
	_characterViewport = Instance.new("ViewportFrame")
	_characterViewport.Name = "PlaneViewport"
	_characterViewport.Size = UDim2.new(0, 460, 0, 320)
	_characterViewport.AnchorPoint = Vector2.new(0.5, 0.5)
	_characterViewport.Position = UDim2.new(0.7, 0, 0.32, 0)
	_characterViewport.BackgroundTransparency = 1
	_characterViewport.Parent = _frame
	
	-- Decorative border around viewport
	local viewportBorder = Instance.new("Frame")
	viewportBorder.Name = "ViewportBorder"
	viewportBorder.Size = UDim2.new(1, 8, 1, 8)
	viewportBorder.Position = UDim2.new(0, -4, 0, -4)
	viewportBorder.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	viewportBorder.BackgroundTransparency = 0.7
	viewportBorder.BorderSizePixel = 0
	viewportBorder.ZIndex = -1
	viewportBorder.Parent = _characterViewport
	
	local borderCorner = Instance.new("UICorner")
	borderCorner.CornerRadius = UDim.new(0, 12)
	borderCorner.Parent = viewportBorder
	
	-- Status label
	_statusLabel = Instance.new("TextLabel")
	_statusLabel.Name = "StatusLabel"
	_statusLabel.Size = UDim2.new(0, 480, 0, 22)
	_statusLabel.Position = UDim2.new(0.7, -240, 0.53, 0)
	_statusLabel.BackgroundTransparency = 1
	_statusLabel.Text = "Loading game assets..."
	_statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	_statusLabel.TextSize = 18
	_statusLabel.Font = Enum.Font.GothamMedium
	_statusLabel.TextXAlignment = Enum.TextXAlignment.Center
	_statusLabel.Parent = _frame
	
	-- Progress bar background (enhanced design)
	_progressBar = Instance.new("Frame")
	_progressBar.Name = "ProgressBar"
	_progressBar.Size = UDim2.new(0, 480, 0, 12)
	_progressBar.Position = UDim2.new(0.7, -240, 0.57, 0)
	_progressBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	_progressBar.BackgroundTransparency = 0.6
	_progressBar.BorderSizePixel = 0
	_progressBar.Parent = _frame
	
	local progressBarCorner = Instance.new("UICorner")
	progressBarCorner.CornerRadius = UDim.new(0, 8)
	progressBarCorner.Parent = _progressBar
	
	-- Progress bar stroke for better visibility
	local progressStroke = Instance.new("UIStroke")
	progressStroke.Color = Color3.fromRGB(255, 255, 255)
	progressStroke.Transparency = 0.5
	progressStroke.Thickness = 2
	progressStroke.Parent = _progressBar
	
	-- Progress bar fill (smooth animation with gradient)
	_progressBarFill = Instance.new("Frame")
	_progressBarFill.Name = "Fill"
	_progressBarFill.Size = UDim2.new(0, 0, 1, 0)
	_progressBarFill.BackgroundColor3 = Color3.fromRGB(100, 200, 255)
	_progressBarFill.BorderSizePixel = 0
	_progressBarFill.Parent = _progressBar
	
	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 8)
	fillCorner.Parent = _progressBarFill
	
	-- Add gradient to fill for visual appeal
	local fillGradient = Instance.new("UIGradient")
	fillGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 220, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 180, 240))
	})
	fillGradient.Rotation = 0
	fillGradient.Parent = _progressBarFill
	
	-- Progress percentage text (on bar)
	local progressText = Instance.new("TextLabel")
	progressText.Name = "ProgressText"
	progressText.Size = UDim2.new(1, 0, 1, 20)
	progressText.Position = UDim2.new(0, 0, 1, 2)
	progressText.BackgroundTransparency = 1
	progressText.Text = "0%"
	progressText.Font = Enum.Font.GothamBold
	progressText.TextSize = 16
	progressText.TextColor3 = Color3.fromRGB(255, 255, 255)
	progressText.TextTransparency = 0.5
	progressText.Parent = _progressBar
	
	-- Loading tip at bottom (better positioned)
	_tipLabel = Instance.new("TextLabel")
	_tipLabel.Name = "TipLabel"
	_tipLabel.Size = UDim2.new(0, 520, 0, 34)
	_tipLabel.Position = UDim2.new(0.5, -260, 0.92, 0)
	_tipLabel.BackgroundTransparency = 1
	_tipLabel.Text = getRandomTip()
	_tipLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	_tipLabel.TextSize = 15
	_tipLabel.Font = Enum.Font.GothamMedium
	_tipLabel.TextWrapped = true
	_tipLabel.TextXAlignment = Enum.TextXAlignment.Center
	_tipLabel.TextTransparency = 0.4
	_tipLabel.Parent = _frame
	
	-- Start button (enhanced "Press to Play" style)
	_startButton = Instance.new("TextButton")
	_startButton.Name = "StartButton"
	_startButton.Size = UDim2.new(0, 0, 0, 0)  -- Start invisible
	_startButton.Position = UDim2.new(0.7, 0, 0.72, 0)
	_startButton.AnchorPoint = Vector2.new(0.5, 0.5)
	_startButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	_startButton.BackgroundTransparency = 0.15
	_startButton.Text = "PRESS TO START"
	_startButton.Font = Enum.Font.GothamBold
	_startButton.TextSize = 28
	_startButton.TextColor3 = Color3.fromRGB(80, 140, 180)
	_startButton.Visible = false
	_startButton.BorderSizePixel = 0
	_startButton.AutoButtonColor = false
	_startButton.Parent = _frame
	
	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 30)
	buttonCorner.Parent = _startButton
	
	-- Button stroke for better visibility
	local buttonStroke = Instance.new("UIStroke")
	buttonStroke.Color = Color3.fromRGB(255, 255, 255)
	buttonStroke.Transparency = 0.3
	buttonStroke.Thickness = 2
	buttonStroke.Parent = _startButton
	
	-- Button click handler
	_startButton.MouseButton1Click:Connect(function()
		LoadingScreen.hide()
	end)
	
	-- Enhanced hover effect
	_startButton.MouseEnter:Connect(function()
		TweenService:Create(_startButton, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {
			BackgroundTransparency = 0,
			TextSize = 30,
			TextColor3 = Color3.fromRGB(60, 120, 160)
		}):Play()
		if buttonStroke then
			TweenService:Create(buttonStroke, TweenInfo.new(0.25), {
				Transparency = 0
			}):Play()
		end
	end)
	
	_startButton.MouseLeave:Connect(function()
		TweenService:Create(_startButton, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {
			BackgroundTransparency = 0.15,
			TextSize = 28,
			TextColor3 = Color3.fromRGB(80, 140, 180)
		}):Play()
		if buttonStroke then
			TweenService:Create(buttonStroke, TweenInfo.new(0.25), {
				Transparency = 0.3
			}):Play()
		end
	end)
	
	_gui.Parent = playerGui
	
	print("[LoadingScreen] ✅ GUI created")

	-- Settings panel (shown before Start; user applies settings first)
	_settingsPanel = Instance.new("Frame")
	_settingsPanel.Name = "SettingsPanel"
	_settingsPanel.Size = UDim2.new(0, 520, 0, 160)
	_settingsPanel.Position = UDim2.new(0.5, -260, 0.74, 0)
	_settingsPanel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	_settingsPanel.BackgroundTransparency = 0.09
	_settingsPanel.BorderSizePixel = 0
	_settingsPanel.Visible = false
	_settingsPanel.Parent = _frame

	local spCorner = Instance.new("UICorner")
	spCorner.CornerRadius = UDim.new(0, 12)
	spCorner.Parent = _settingsPanel

	local spStroke = Instance.new("UIStroke")
	spStroke.Color = Color3.fromRGB(255, 255, 255)
	spStroke.Transparency = 0.2
	spStroke.Thickness = 2
	spStroke.Parent = _settingsPanel

	local spTitle = Instance.new("TextLabel")
	spTitle.Name = "Title"
	spTitle.Size = UDim2.new(1, -20, 0, 28)
	spTitle.Position = UDim2.new(0, 10, 0, 10)
	spTitle.BackgroundTransparency = 1
	spTitle.Text = "Choose your graphics preset"
	spTitle.Font = Enum.Font.GothamBold
	spTitle.TextSize = 20
	spTitle.TextColor3 = Color3.fromRGB(80, 140, 180)
	spTitle.TextXAlignment = Enum.TextXAlignment.Left
	spTitle.Parent = _settingsPanel

	-- Preset buttons container
	local presetsContainer = Instance.new("Frame")
	presetsContainer.Name = "Presets"
	presetsContainer.Size = UDim2.new(1, -20, 0, 50)
	presetsContainer.Position = UDim2.new(0, 10, 0, 50)
	presetsContainer.BackgroundTransparency = 1
	presetsContainer.Parent = _settingsPanel

	local uiList = Instance.new("UIListLayout")
	uiList.FillDirection = Enum.FillDirection.Horizontal
	uiList.HorizontalAlignment = Enum.HorizontalAlignment.Left
	uiList.VerticalAlignment = Enum.VerticalAlignment.Top
	uiList.Padding = UDim.new(0, 10)
	uiList.Parent = presetsContainer

	_presetButtons = {}
	local presetNames = {"Low", "Medium", "High"}
	for _, name in ipairs(presetNames) do
		local btn = Instance.new("TextButton")
		btn.Name = name .. "Preset"
		btn.Size = UDim2.new(0, 150, 1, 0)
		btn.BackgroundColor3 = Color3.fromRGB(245, 250, 255)
		btn.Text = name
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 18
		btn.TextColor3 = Color3.fromRGB(60, 120, 160)
		btn.AutoButtonColor = true
		btn.Parent = presetsContainer

		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 10)
		c.Parent = btn

		local s = Instance.new("UIStroke")
		s.Color = Color3.fromRGB(200, 220, 240)
		s.Thickness = 2
		s.Transparency = 0.2
		s.Parent = btn

		btn.MouseButton1Click:Connect(function()
			_selectedPreset = name
			-- Visually indicate selection
			for _, b in ipairs(_presetButtons :: {TextButton}) do
				b.BackgroundColor3 = if b == btn then Color3.fromRGB(230, 245, 255) else Color3.fromRGB(245, 250, 255)
			end
		end)

		table.insert(_presetButtons :: {TextButton}, btn)
	end

	-- Default selection
	_selectedPreset = "Medium"
	for _, b in ipairs(_presetButtons :: {TextButton}) do
		if b.Name == "MediumPreset" then
			b.BackgroundColor3 = Color3.fromRGB(230, 245, 255)
		end
	end

	_applySettingsButton = Instance.new("TextButton")
	_applySettingsButton.Name = "ApplyButton"
	_applySettingsButton.Size = UDim2.new(0, 220, 0, 44)
	_applySettingsButton.Position = UDim2.new(1, -230, 1, -54)
	_applySettingsButton.AnchorPoint = Vector2.new(0, 0)
	_applySettingsButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	_applySettingsButton.Text = "Apply & Continue"
	_applySettingsButton.Font = Enum.Font.GothamBold
	_applySettingsButton.TextSize = 20
	_applySettingsButton.TextColor3 = Color3.fromRGB(60, 120, 160)
	_applySettingsButton.BorderSizePixel = 0
	_applySettingsButton.Parent = _settingsPanel

	local abCorner = Instance.new("UICorner")
	abCorner.CornerRadius = UDim.new(0, 10)
	abCorner.Parent = _applySettingsButton

	local abStroke = Instance.new("UIStroke")
	abStroke.Color = Color3.fromRGB(255, 255, 255)
	abStroke.Transparency = 0.2
	abStroke.Thickness = 2
	abStroke.Parent = _applySettingsButton

	_applySettingsButton.MouseButton1Click:Connect(function()
		-- Apply selected preset, then show Start
		applyGraphicsPreset(_selectedPreset)
		_settingsPanel.Visible = false
		-- Reveal Start button with animation
		_startButton.Visible = true
		_startButton.Size = UDim2.new(0, 0, 0, 0)
		local tween = TweenService:Create(_startButton, TweenInfo.new(0.6, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, 320, 0, 60)
		})
		tween:Play()
	end)
end

--[[
	Setup Nook plane preview in viewport
]]
local function setupPlanePreview()
	-- Try to get the Nook plane from ReplicatedStorage
	local nookPlane = ReplicatedStorage:FindFirstChild("NookPlane")
	
	if not nookPlane then
		warn("[LoadingScreen] ⚠️ NookPlane not found in ReplicatedStorage, using fallback")
		-- Create a simple fallback plane
		local fallbackPlane = Instance.new("Model")
		fallbackPlane.Name = "NookPlane"
		
		local body = Instance.new("Part")
		body.Name = "Body"
		body.Size = Vector3.new(10, 5, 15)
		body.Transparency = 0.3
		body.Color = Color3.fromRGB(255, 200, 100)
		body.Material = Enum.Material.SmoothPlastic
		body.CanCollide = false
		body.Anchored = true
		body.Parent = fallbackPlane
		
		fallbackPlane.PrimaryPart = body
		fallbackPlane.Parent = _characterViewport
		
		-- Setup orientation to face right, camera (side view), and gentle bobbing
		local viewportCamera = Instance.new("Camera")
		viewportCamera.Parent = _characterViewport
		_characterViewport.CurrentCamera = viewportCamera
		-- Yaw rotate to face right in the viewport
		local baseCFrame = CFrame.new(body.Position) * CFrame.Angles(0, _YAW_TO_FACE_RIGHT, 0) * CFrame.new(0, 1.2, 0)
		body.CFrame = baseCFrame
		-- Place camera in front of the plane's side (along +Z) for a clear right-facing silhouette
		viewportCamera.CFrame = CFrame.new(body.Position + Vector3.new(0, 7, 22), body.Position)

		-- Animate bobbing
		task.spawn(function()
			local t = 0
			while fallbackPlane and fallbackPlane.Parent do
				if body and body.Parent then
					t = t + 0.05
					local bob = math.sin(t * 1.2) * 0.7
					local pitch = math.rad(math.sin(t * 1.2) * 2)
					local roll = math.rad(math.cos(t * 0.8) * 0.8)
					body.CFrame = baseCFrame * CFrame.new(0, bob, 0) * CFrame.Angles(pitch, 0, roll)
				end
				task.wait(0.05)
			end
		end)
		
		print("[LoadingScreen] ✅ Fallback plane preview setup")
		return
	end
	
	-- Clone the plane model from ReplicatedStorage
	local planeModel = nookPlane:Clone()
	planeModel.Name = "NookPlane"
	
	-- Clean up scripts
	for _, descendant in ipairs(planeModel:GetDescendants()) do
		if descendant:IsA("Script") or descendant:IsA("LocalScript") then
			descendant:Destroy()
		elseif descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
		end
	end
	
	-- Ensure PrimaryPart exists
	if not planeModel.PrimaryPart then
		local primary = planeModel:FindFirstChildWhichIsA("BasePart", true)
		if primary then
			planeModel.PrimaryPart = primary
		end
	end
	
	-- Position in viewport
	planeModel.Parent = _characterViewport
	
	-- Create camera for viewport
	local viewportCamera = Instance.new("Camera")
	viewportCamera.Parent = _characterViewport
	_characterViewport.CurrentCamera = viewportCamera
	
		-- Position and orient plane to face right; show from the side
	local primaryPart = planeModel.PrimaryPart
	if primaryPart then
			-- Yaw rotate to face right and slightly elevate baseline
			local baseCFrame = CFrame.new(primaryPart.Position) * CFrame.Angles(0, _YAW_TO_FACE_RIGHT, 0) * CFrame.new(0, 1.5, 0)
		primaryPart.CFrame = baseCFrame
			-- Place camera along +Z for side-on view (plane nose points screen-right)
			viewportCamera.CFrame = CFrame.new(primaryPart.Position + Vector3.new(0, 10, 30), primaryPart.Position)

		-- Animate plane with gentle up/down bobbing and subtle tilt (side view)
		task.spawn(function()
			local t = 0
			while planeModel and planeModel.Parent do
				if primaryPart and primaryPart.Parent then
					t = t + 0.05
					local bob = math.sin(t * 1.2) * 0.9 -- vertical bob amplitude
					local pitch = math.rad(math.sin(t * 1.2) * 2.5)
					local roll = math.rad(math.cos(t * 0.8) * 1)
					primaryPart.CFrame = baseCFrame * CFrame.new(0, bob, 0) * CFrame.Angles(pitch, 0, roll)
				end
				task.wait(0.05)
			end
		end)
	end
	
	print("[LoadingScreen] ✅ Nook plane preview setup complete")
end

--[[
	Preload game assets with progress updates
]]
local function preloadAssets()
	print("[LoadingScreen] 🎮 Starting asset preload...")
	_statusLabel.Text = "Loading game assets..."
	
	local totalAssets = #ASSETS_TO_PRELOAD
	local loadedAssets = 0
	
	-- Preload assets one by one with progress updates
	for i, assetId in ipairs(ASSETS_TO_PRELOAD) do
		local success, err = pcall(function()
			ContentProvider:PreloadAsync({assetId})
		end)
		
		if success then
			loadedAssets = loadedAssets + 1
			print("[LoadingScreen] Loaded asset:", assetId)
		else
			warn("[LoadingScreen] Failed to load asset:", assetId, err)
		end
		
		-- Update progress
		local progress = loadedAssets / totalAssets
		local percentage = math.floor(progress * 100)
		_progressBarFill.Size = UDim2.new(progress, 0, 1, 0)
		
		-- Update percentage text
		local progressText = _progressBar:FindFirstChild("ProgressText")
		if progressText then
			progressText.Text = percentage .. "%"
		end
		
		task.wait(0.1)  -- Small delay for visual feedback
	end
	
	-- Complete
	_progressBarFill.Size = UDim2.new(1, 0, 1, 0)
	local progressText = _progressBar:FindFirstChild("ProgressText")
	if progressText then
		progressText.Text = "100%"
	end
	
	_statusLabel.Text = "Choose your settings"
	-- Show settings panel first, then gate Start behind Apply
	if _settingsPanel then
		_settingsPanel.Visible = true
		-- Ensure Start remains hidden until Apply
		_startButton.Visible = false
	else
		-- Fallback: if panel missing, show Start directly
		_startButton.Visible = true
	end
	_isReady = true
	-- DON'T set isLoading to false yet - wait for button click!
	-- LoadingScreen.isLoading will be set to false in hide() function
	
	-- Animate button entrance (smooth pop-in) only if settings panel isn't gating it
	if not (_settingsPanel and _settingsPanel.Visible) then
		_startButton.Visible = true
		_startButton.Size = UDim2.new(0, 0, 0, 0)
		local tween = TweenService:Create(_startButton, TweenInfo.new(0.6, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, 320, 0, 60)
		})
		tween:Play()
	end
	
	-- Pulsing animation
	task.spawn(function()
		while _startButton and _startButton.Parent do
			TweenService:Create(_startButton, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
				TextTransparency = 0.3
			}):Play()
			task.wait(1)
			TweenService:Create(_startButton, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
				TextTransparency = 0
			}):Play()
			task.wait(1)
		end
	end)
	
	print("[LoadingScreen] ✅ All assets loaded!")
end

--[[
	Initialize and show loading screen
]]
function LoadingScreen.init()
	-- Disable player controls during loading (cutscene mode)
	local player = Players.LocalPlayer

	-- Hide Roblox top bar to prevent overlap with loading UI (can be re-enabled later)
	pcall(function()
		StarterGui:SetCore("TopbarEnabled", false)
	end)
	
	-- Create GUI first
	createGUI()
	
	-- Setup plane preview (non-blocking, after assets load)
	task.spawn(function()
		-- Wait a bit for assets to start loading
		task.wait(0.3)
		setupPlanePreview()
	end)
	
	-- Freeze player if character exists
	if player.Character then
		local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = 0
			humanoid.JumpPower = 0
			humanoid.JumpHeight = 0
		end
	end
	
	-- Hide core GUI during loading
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
	end)
	
	-- Keep user input enabled so button can be clicked
	local UserInputService = game:GetService("UserInputService")
	-- DON'T set ModalEnabled - it blocks button clicks!
	-- UserInputService.ModalEnabled = true  -- ❌ This blocks buttons!
	
	-- IMPORTANT: Keep mouse free during loading screen
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	UserInputService.MouseIconEnabled = true
	
	-- Start preloading immediately
	task.wait(0.5)
	preloadAssets()
end

--[[
	Hide the loading screen
]]
function LoadingScreen.hide()
	print("[LoadingScreen] Hiding loading screen...")
	
	-- IMPORTANT: Set isLoading to false NOW so camera can initialize
	LoadingScreen.isLoading = false
	
	-- Re-enable player controls
	local player = Players.LocalPlayer
	local character = player.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = 16
			humanoid.JumpPower = 50
			humanoid.JumpHeight = 7.2
		end
	end
	
	-- Restore core GUI and top bar
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
		StarterGui:SetCore("TopbarEnabled", true)
	end)
	
	-- Re-enable user input and FREE THE MOUSE
	local UserInputService = game:GetService("UserInputService")
	-- No need to reset ModalEnabled since we never set it
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default  -- FREE THE MOUSE!
	UserInputService.MouseIconEnabled = true
	
	-- Fade out
	local fadeOutInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	local frameTween = TweenService:Create(_frame, fadeOutInfo, {BackgroundTransparency = 1})
	
	-- Fade out all children
	for _, child in ipairs(_frame:GetDescendants()) do
		if child:IsA("GuiObject") then
			if child:IsA("TextLabel") or child:IsA("TextButton") then
				TweenService:Create(child, fadeOutInfo, {TextTransparency = 1}):Play()
			end
			TweenService:Create(child, fadeOutInfo, {BackgroundTransparency = 1}):Play()
		end
	end
	
	frameTween:Play()
	frameTween.Completed:Wait()
	
	_isShowing = false
	
	-- Destroy GUI
	if _gui then
		_gui:Destroy()
		_gui = nil
	end
	
	print("[LoadingScreen] ✅ Loading screen hidden")
end

return LoadingScreen
