--[[
	IslandGenerationGUI.client.luau
	
	Client-side GUI for island generation system.
	Attaches to NooksTent model in Workspace as a SurfaceGui.
	
	Features:
	- Generate button to create island layout
	- Clear button to remove preview
	- Save button to permanently store layout
	- Progress bar showing generation steps
	- Statistics display (trees, rocks, flowers)
	- ACNH-themed styling
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

-- Wait for RemoteEvents to be created by server
local remoteFolder = ReplicatedStorage:WaitForChild("IslandGenRemotes", 10)
if not remoteFolder then
	warn("[IslandGenerationGUI] ⚠️ RemoteEvents not found - server may not be running")
	return
end

local generateRemote = remoteFolder:WaitForChild("GenerateIsland")
local saveRemote = remoteFolder:WaitForChild("SaveIsland")
local clearRemote = remoteFolder:WaitForChild("ClearIsland")
local progressRemote = remoteFolder:WaitForChild("UpdateProgress")

-- ACNH Colors
local COLORS = {
	background = Color3.fromRGB(255, 251, 231), -- Cream
	title = Color3.fromRGB(120, 100, 80), -- Brown
	text = Color3.fromRGB(80, 60, 40), -- Dark brown
	accent = Color3.fromRGB(4, 175, 166), -- Teal
	button = {
		generate = Color3.fromRGB(4, 175, 166), -- Teal
		clear = Color3.fromRGB(220, 80, 80), -- Red
		save = Color3.fromRGB(100, 180, 100) -- Green
	}
}

-- Find Whiteboard model
local function findWhiteboard(): Model?
	local whiteboard = Workspace:FindFirstChild("Whiteboard")
	if not whiteboard then
		warn("[IslandGenerationGUI] ⚠️ Whiteboard model not found in Workspace!")
		warn("[IslandGenerationGUI] Please create a model named 'Whiteboard' in Workspace for the GUI to attach to.")
		return nil
	end
	return whiteboard
end

-- Create GUI elements
local function createGUI(whiteboard: Model)
	-- Create SurfaceGui
	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Name = "IslandGeneratorGUI"
	surfaceGui.Face = Enum.NormalId.Front
	surfaceGui.Adornee = whiteboard:FindFirstChildWhichIsA("BasePart") -- Attach to whiteboard surface
	surfaceGui.AlwaysOnTop = false -- Draw on the actual surface
	surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surfaceGui.PixelsPerStud = 50 -- Lower value = bigger UI relative to surface
	surfaceGui.Parent = whiteboard
	
	-- Main frame - FILL THE ENTIRE WHITEBOARD SURFACE
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(1, 0, 1, 0) -- FILL 100% of surface
	mainFrame.Position = UDim2.new(0, 0, 0, 0)
	mainFrame.BackgroundColor3 = COLORS.background
	mainFrame.BorderSizePixel = 0
	mainFrame.Rotation = 180 -- Flip GUI 180 degrees so it's right-side up
	mainFrame.Parent = surfaceGui
	
	-- Rounded corners
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = mainFrame
	
	-- Padding - proportional to screen
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0.02, 0) -- 2% of height
	padding.PaddingBottom = UDim.new(0.02, 0)
	padding.PaddingLeft = UDim.new(0.02, 0)
	padding.PaddingRight = UDim.new(0.02, 0)
	padding.Parent = mainFrame
	
	-- Title - proportional sizing
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0.12, 0) -- 12% of height
	title.Position = UDim2.new(0, 0, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = "🏝️ Island Generator"
	title.TextColor3 = COLORS.title
	title.TextScaled = true -- Auto-scale text
	title.Font = Enum.Font.GothamBold
	title.Parent = mainFrame
	
	-- Text size constraint for title
	local titleConstraint = Instance.new("UITextSizeConstraint")
	titleConstraint.MaxTextSize = 80
	titleConstraint.MinTextSize = 20
	titleConstraint.Parent = title
	
	-- Status label - proportional
	local statusLabel = Instance.new("TextLabel")
	statusLabel.Name = "StatusLabel"
	statusLabel.Size = UDim2.new(1, 0, 0.08, 0) -- 8% of height
	statusLabel.Position = UDim2.new(0, 0, 0.13, 0) -- Below title
	statusLabel.BackgroundTransparency = 1
	statusLabel.Text = "Ready to generate"
	statusLabel.TextColor3 = COLORS.text
	statusLabel.TextScaled = true
	statusLabel.Font = Enum.Font.Gotham
	statusLabel.Parent = mainFrame
	
	local statusConstraint = Instance.new("UITextSizeConstraint")
	statusConstraint.MaxTextSize = 40
	statusConstraint.MinTextSize = 12
	statusConstraint.Parent = statusLabel
	
	-- Progress bar background - proportional
	local progressBg = Instance.new("Frame")
	progressBg.Name = "ProgressBackground"
	progressBg.Size = UDim2.new(1, 0, 0.06, 0) -- 6% of height
	progressBg.Position = UDim2.new(0, 0, 0.22, 0) -- Below status
	progressBg.BackgroundColor3 = Color3.fromRGB(200, 190, 170)
	progressBg.BorderSizePixel = 0
	progressBg.Parent = mainFrame
	
	local progressCorner = Instance.new("UICorner")
	progressCorner.CornerRadius = UDim.new(0.3, 0) -- Proportional corner
	progressCorner.Parent = progressBg
	
	-- Progress bar fill
	local progressFill = Instance.new("Frame")
	progressFill.Name = "ProgressFill"
	progressFill.Size = UDim2.new(0, 0, 1, 0)
	progressFill.BackgroundColor3 = COLORS.accent
	progressFill.BorderSizePixel = 0
	progressFill.Parent = progressBg
	
	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0.3, 0)
	fillCorner.Parent = progressFill
	
	-- Stats panel - proportional
	local statsPanel = Instance.new("Frame")
	statsPanel.Name = "StatsPanel"
	statsPanel.Size = UDim2.new(1, 0, 0.25, 0) -- 25% of height
	statsPanel.Position = UDim2.new(0, 0, 0.30, 0) -- Below progress bar
	statsPanel.BackgroundColor3 = Color3.fromRGB(240, 236, 216)
	statsPanel.BorderSizePixel = 0
	statsPanel.Parent = mainFrame
	
	local statsCorner = Instance.new("UICorner")
	statsCorner.CornerRadius = UDim.new(0.05, 0)
	statsCorner.Parent = statsPanel
	
	-- Stats text - proportional with TextScaled
	local statsText = Instance.new("TextLabel")
	statsText.Name = "StatsText"
	statsText.Size = UDim2.new(0.9, 0, 0.9, 0)
	statsText.Position = UDim2.new(0.05, 0, 0.05, 0)
	statsText.BackgroundTransparency = 1
	statsText.Text = "🌳 Trees: 0\n🪨 Rocks: 0\n🌸 Flowers: 0"
	statsText.TextColor3 = COLORS.text
	statsText.TextScaled = true
	statsText.Font = Enum.Font.GothamMedium
	statsText.TextXAlignment = Enum.TextXAlignment.Left
	statsText.TextYAlignment = Enum.TextYAlignment.Top
	statsText.Parent = statsPanel
	
	local statsConstraint = Instance.new("UITextSizeConstraint")
	statsConstraint.MaxTextSize = 50
	statsConstraint.MinTextSize = 14
	statsConstraint.Parent = statsText
	
	-- Button container - proportional
	local buttonContainer = Instance.new("Frame")
	buttonContainer.Name = "ButtonContainer"
	buttonContainer.Size = UDim2.new(1, 0, 0.15, 0) -- 15% of height
	buttonContainer.Position = UDim2.new(0, 0, 0.82, 0) -- Near bottom
	buttonContainer.BackgroundTransparency = 1
	buttonContainer.Parent = mainFrame
	
	-- Button creator helper - with TextScaled
	local function createButton(name: string, text: string, color: Color3, position: UDim2): TextButton
		local button = Instance.new("TextButton")
		button.Name = name
		button.Size = UDim2.new(0.3, -10, 1, 0) -- 30% width with spacing
		button.Position = position
		button.BackgroundColor3 = color
		button.BorderSizePixel = 0
		button.Text = text
		button.TextColor3 = Color3.fromRGB(255, 255, 255)
		button.TextScaled = true
		button.Font = Enum.Font.GothamBold
		button.Parent = buttonContainer
		
		local btnConstraint = Instance.new("UITextSizeConstraint")
		btnConstraint.MaxTextSize = 40
		btnConstraint.MinTextSize = 10
		btnConstraint.Parent = button
		
		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0.15, 0)
		btnCorner.Parent = button
		
		-- Hover effect
		button.MouseEnter:Connect(function()
			button.BackgroundColor3 = Color3.new(
				math.min(color.R * 1.2, 1),
				math.min(color.G * 1.2, 1),
				math.min(color.B * 1.2, 1)
			)
		end)
		
		button.MouseLeave:Connect(function()
			button.BackgroundColor3 = color
		end)
		
		return button
	end
	
	-- Create buttons
	local generateBtn = createButton("GenerateButton", "Generate", COLORS.button.generate, UDim2.new(0, 0, 0, 0))
	local clearBtn = createButton("ClearButton", "Clear", COLORS.button.clear, UDim2.new(0.35, 0, 0, 0))
	local saveBtn = createButton("SaveButton", "Save", COLORS.button.save, UDim2.new(0.7, 0, 0, 0))
	
	-- Return GUI references
	return {
		gui = surfaceGui,
		statusLabel = statusLabel,
		progressFill = progressFill,
		statsText = statsText,
		generateBtn = generateBtn,
		clearBtn = clearBtn,
		saveBtn = saveBtn
	}
end

-- Update progress display
local function updateProgress(data: {step: string, progress: number, stats: {trees: number, rocks: number, flowers: number}}, gui)
	-- Update status text
	gui.statusLabel.Text = data.step
	
	-- Update progress bar
	gui.progressFill:TweenSize(
		UDim2.new(data.progress / 100, 0, 1, 0),
		Enum.EasingDirection.Out,
		Enum.EasingStyle.Quad,
		0.3,
		true
	)
	
	-- Update stats
	gui.statsText.Text = string.format(
		"🌳 Trees: %d\n🪨 Rocks: %d\n🌸 Flowers: %d",
		data.stats.trees,
		data.stats.rocks,
		data.stats.flowers
	)
end

-- Main initialization
local function initialize()
	print("[IslandGenerationGUI] 🎨 Initializing GUI...")
	
	-- Find Whiteboard
	local whiteboard = findWhiteboard()
	if not whiteboard then
		-- Try again in 5 seconds
		task.wait(5)
		whiteboard = findWhiteboard()
		if not whiteboard then
			return
		end
	end
	
	-- Create GUI
	local gui = createGUI(whiteboard)
	if not gui then
		warn("[IslandGenerationGUI] ❌ Failed to create GUI")
		return
	end
	
	print("[IslandGenerationGUI] ✅ GUI created and attached to", whiteboard.Name)
	
	-- Connect buttons
	gui.generateBtn.MouseButton1Click:Connect(function()
		print("[IslandGenerationGUI] 🎮 Generate button clicked")
		generateRemote:FireServer()
	end)
	
	gui.clearBtn.MouseButton1Click:Connect(function()
		print("[IslandGenerationGUI] 🎮 Clear button clicked")
		clearRemote:FireServer()
	end)
	
	gui.saveBtn.MouseButton1Click:Connect(function()
		print("[IslandGenerationGUI] 🎮 Save button clicked")
		saveRemote:FireServer()
	end)
	
	-- Connect progress updates
	progressRemote.OnClientEvent:Connect(function(data)
		updateProgress(data, gui)
	end)
	
	print("[IslandGenerationGUI] 🎮 All buttons and events connected")
end

-- Start initialization
initialize()
