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

local LoadingScreen = {}
LoadingScreen.isLoading = true  -- Exposed property for checking load status

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
	
	-- Background frame (sky blue like ACNH)
	_frame = Instance.new("Frame")
	_frame.Name = "LoadingFrame"
	_frame.Size = UDim2.new(1, 0, 1, 0)
	_frame.Position = UDim2.new(0, 0, 0, 0)
	_frame.BackgroundColor3 = Color3.fromRGB(135, 206, 235) -- Sky blue
	_frame.BackgroundTransparency = 0
	_frame.BorderSizePixel = 0
	_frame.Parent = _gui
	
	-- Gradient for depth
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(135, 206, 235)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 180, 220))
	})
	gradient.Rotation = 90
	gradient.Parent = _frame
	
	-- Title
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(0, 600, 0, 80)
	titleLabel.Position = UDim2.new(0.5, -300, 0.08, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "Animal Crossing CE"
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextSize = 52
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.TextStrokeTransparency = 0.3
	titleLabel.TextStrokeColor3 = Color3.fromRGB(80, 140, 180)
	titleLabel.Parent = _frame
	
	-- Subtitle
	local subtitleLabel = Instance.new("TextLabel")
	subtitleLabel.Name = "Subtitle"
	subtitleLabel.Size = UDim2.new(0, 400, 0, 30)
	subtitleLabel.Position = UDim2.new(0.5, -200, 0.16, 0)
	subtitleLabel.BackgroundTransparency = 1
	subtitleLabel.Text = "Community Edition"
	subtitleLabel.Font = Enum.Font.Gotham
	subtitleLabel.TextSize = 20
	subtitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	subtitleLabel.TextTransparency = 0.3
	subtitleLabel.Parent = _frame
	
	-- Character viewport (larger, centered)
	_characterViewport = Instance.new("ViewportFrame")
	_characterViewport.Name = "CharacterViewport"
	_characterViewport.Size = UDim2.new(0, 500, 0, 350)
	_characterViewport.Position = UDim2.new(0.5, -250, 0.25, 0)
	_characterViewport.BackgroundTransparency = 1
	_characterViewport.Parent = _frame
	
	-- Status label
	_statusLabel = Instance.new("TextLabel")
	_statusLabel.Name = "StatusLabel"
	_statusLabel.Size = UDim2.new(0, 600, 0, 25)
	_statusLabel.Position = UDim2.new(0.5, -300, 0.65, 0)
	_statusLabel.BackgroundTransparency = 1
	_statusLabel.Text = "Loading game assets..."
	_statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	_statusLabel.TextSize = 18
	_statusLabel.Font = Enum.Font.GothamMedium
	_statusLabel.TextXAlignment = Enum.TextXAlignment.Center
	_statusLabel.Parent = _frame
	
	-- Progress bar background (cleaner design)
	_progressBar = Instance.new("Frame")
	_progressBar.Name = "ProgressBar"
	_progressBar.Size = UDim2.new(0, 500, 0, 10)
	_progressBar.Position = UDim2.new(0.5, -250, 0.70, 0)
	_progressBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	_progressBar.BackgroundTransparency = 0.7
	_progressBar.BorderSizePixel = 0
	_progressBar.Parent = _frame
	
	local progressBarCorner = Instance.new("UICorner")
	progressBarCorner.CornerRadius = UDim.new(0, 6)
	progressBarCorner.Parent = _progressBar
	
	-- Progress bar fill (smooth animation)
	_progressBarFill = Instance.new("Frame")
	_progressBarFill.Name = "Fill"
	_progressBarFill.Size = UDim2.new(0, 0, 1, 0)
	_progressBarFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	_progressBarFill.BorderSizePixel = 0
	_progressBarFill.Parent = _progressBar
	
	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 6)
	fillCorner.Parent = _progressBarFill
	
	-- Progress percentage text (on bar)
	local progressText = Instance.new("TextLabel")
	progressText.Name = "ProgressText"
	progressText.Size = UDim2.new(1, 0, 1, 25)
	progressText.Position = UDim2.new(0, 0, 1, 3)
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
	_tipLabel.Size = UDim2.new(0, 700, 0, 40)
	_tipLabel.Position = UDim2.new(0.5, -350, 0.90, 0)
	_tipLabel.BackgroundTransparency = 1
	_tipLabel.Text = getRandomTip()
	_tipLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	_tipLabel.TextSize = 15
	_tipLabel.Font = Enum.Font.GothamMedium
	_tipLabel.TextWrapped = true
	_tipLabel.TextXAlignment = Enum.TextXAlignment.Center
	_tipLabel.TextTransparency = 0.4
	_tipLabel.Parent = _frame
	
	-- Start button (pulsing "Press to Play" style)
	_startButton = Instance.new("TextButton")
	_startButton.Name = "StartButton"
	_startButton.Size = UDim2.new(0, 0, 0, 0)  -- Start invisible
	_startButton.Position = UDim2.new(0.5, 0, 0.78, 0)
	_startButton.AnchorPoint = Vector2.new(0.5, 0.5)
	_startButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	_startButton.BackgroundTransparency = 0.2
	_startButton.Text = "PRESS TO START"
	_startButton.Font = Enum.Font.GothamBold
	_startButton.TextSize = 26
	_startButton.TextColor3 = Color3.fromRGB(80, 140, 180)
	_startButton.Visible = false
	_startButton.BorderSizePixel = 0
	_startButton.AutoButtonColor = false
	_startButton.Parent = _frame
	
	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 25)
	buttonCorner.Parent = _startButton
	
	-- Button click handler
	_startButton.MouseButton1Click:Connect(function()
		LoadingScreen.hide()
	end)
	
	-- Hover effect
	_startButton.MouseEnter:Connect(function()
		TweenService:Create(_startButton, TweenInfo.new(0.2), {
			BackgroundTransparency = 0,
			TextSize = 28
		}):Play()
	end)
	
	_startButton.MouseLeave:Connect(function()
		TweenService:Create(_startButton, TweenInfo.new(0.2), {
			BackgroundTransparency = 0.2,
			TextSize = 26
		}):Play()
	end)
	
	_gui.Parent = playerGui
	
	print("[LoadingScreen] ✅ GUI created")
end

--[[
	Setup character preview in viewport
]]
local function setupCharacterPreview()
	local player = Players.LocalPlayer
	local character = player.Character or player.CharacterAdded:Wait()
	
	-- Wait a bit for character to fully load
	task.wait(0.5)
	
	if not character or not character.Parent then
		warn("[LoadingScreen] Character not available for preview")
		return
	end
	
	-- Clone character
	local success, characterClone = pcall(function()
		return character:Clone()
	end)
	
	if not success or not characterClone then
		warn("[LoadingScreen] Failed to clone character for preview")
		return
	end
	
	-- Clean up clone
	for _, descendant in ipairs(characterClone:GetDescendants()) do
		if descendant:IsA("Script") or descendant:IsA("LocalScript") then
			descendant:Destroy()
		end
	end
	
	-- Position in viewport
	characterClone.Parent = _characterViewport
	
	-- Create camera for viewport
	local viewportCamera = Instance.new("Camera")
	viewportCamera.Parent = _characterViewport
	_characterViewport.CurrentCamera = viewportCamera
	
	-- Position camera
	local hrp = characterClone:FindFirstChild("HumanoidRootPart")
	if hrp then
		viewportCamera.CFrame = CFrame.new(hrp.Position + Vector3.new(5, 2, 5), hrp.Position)
		
		-- Animate character (rotation)
		task.spawn(function()
			while characterClone and characterClone.Parent do
				if hrp and hrp.Parent then
					hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(1), 0)
				end
				task.wait(0.05)
			end
		end)
	end
	
	print("[LoadingScreen] Character preview setup complete")
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
	
	_statusLabel.Text = "Ready to play!"
	_startButton.Visible = true
	_isReady = true
	-- DON'T set isLoading to false yet - wait for button click!
	-- LoadingScreen.isLoading will be set to false in hide() function
	
	-- Animate button entrance (smooth pop-in)
	_startButton.Size = UDim2.new(0, 0, 0, 0)
	local tween = TweenService:Create(_startButton, TweenInfo.new(0.6, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 320, 0, 60)
	})
	tween:Play()
	
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
	
	-- Create GUI first
	createGUI()
	
	-- Try to setup character preview after a delay
	task.spawn(function()
		local character = player.Character or player.CharacterAdded:Wait()
		task.wait(1)  -- Wait for character to fully load
		setupCharacterPreview()
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
	
	-- Restore core GUI
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
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
