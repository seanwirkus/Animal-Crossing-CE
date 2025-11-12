--[[
	StartupKeybindHint.luau
	
	Persistent keybind hint display that shows essential controls.
	Always visible in corner, doesn't interfere with Roblox CoreGui.
	Press F1 to see full keybind guide.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local StartupKeybindHint = {}

local _screenGui = nil
local _hintFrame = nil
local _isMinimized = false

-- Essential keybinds to show
local ESSENTIAL_KEYBINDS = {
	{key = "E", action = "Inventory"},
	{key = "C", action = "Crafting"},
	{key = "T", action = "Tools"},
	{key = "P", action = "NookPhone"},
	{key = "F1", action = "All Controls"},
	{key = "`", action = "Menu"},
}

local function createHintGUI()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")
	
	-- Create ScreenGui with high display order to stay on top
	_screenGui = Instance.new("ScreenGui")
	_screenGui.Name = "StartupKeybindHint"
	_screenGui.DisplayOrder = 100 -- Very high to stay above most GUIs
	_screenGui.ResetOnSpawn = false
	_screenGui.IgnoreGuiInset = false
	_screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	_screenGui.Parent = playerGui
	
	-- Main frame (bottom-right corner)
	_hintFrame = Instance.new("Frame")
	_hintFrame.Name = "HintFrame"
	_hintFrame.Size = UDim2.new(0, 240, 0, 280)
	_hintFrame.Position = UDim2.new(1, -250, 1, -290)
	_hintFrame.AnchorPoint = Vector2.new(0, 0)
	_hintFrame.BackgroundColor3 = Color3.fromRGB(255, 251, 231) -- Cream ACNH color
	_hintFrame.BackgroundTransparency = 0.05
	_hintFrame.BorderSizePixel = 0
	_hintFrame.Parent = _screenGui
	
	local frameCorner = Instance.new("UICorner")
	frameCorner.CornerRadius = UDim.new(0, 12)
	frameCorner.Parent = _hintFrame
	
	local frameStroke = Instance.new("UIStroke")
	frameStroke.Color = Color3.fromRGB(200, 180, 150)
	frameStroke.Thickness = 2
	frameStroke.Transparency = 0.3
	frameStroke.Parent = _hintFrame
	
	-- Drop shadow effect
	local shadow = Instance.new("ImageLabel")
	shadow.Name = "Shadow"
	shadow.Size = UDim2.new(1, 20, 1, 20)
	shadow.Position = UDim2.new(0, -10, 0, -10)
	shadow.BackgroundTransparency = 1
	shadow.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
	shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
	shadow.ImageTransparency = 0.8
	shadow.ScaleType = Enum.ScaleType.Slice
	shadow.ZIndex = -1
	shadow.Parent = _hintFrame
	
	-- Header
	local header = Instance.new("TextLabel")
	header.Name = "Header"
	header.Size = UDim2.new(1, -20, 0, 30)
	header.Position = UDim2.new(0, 10, 0, 8)
	header.BackgroundTransparency = 1
	header.Text = "🎮 CONTROLS"
	header.Font = Enum.Font.GothamBold
	header.TextSize = 16
	header.TextColor3 = Color3.fromRGB(120, 100, 80)
	header.TextXAlignment = Enum.TextXAlignment.Left
	header.Parent = _hintFrame
	
	-- Minimize button
	local minimizeBtn = Instance.new("TextButton")
	minimizeBtn.Name = "MinimizeBtn"
	minimizeBtn.Size = UDim2.new(0, 24, 0, 24)
	minimizeBtn.Position = UDim2.new(1, -34, 0, 8)
	minimizeBtn.BackgroundColor3 = Color3.fromRGB(4, 175, 166)
	minimizeBtn.BorderSizePixel = 0
	minimizeBtn.Text = "−"
	minimizeBtn.Font = Enum.Font.GothamBold
	minimizeBtn.TextSize = 20
	minimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	minimizeBtn.Parent = _hintFrame
	
	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 6)
	btnCorner.Parent = minimizeBtn
	
	-- Content container (for minimizing)
	local contentFrame = Instance.new("Frame")
	contentFrame.Name = "ContentFrame"
	contentFrame.Size = UDim2.new(1, -20, 1, -48)
	contentFrame.Position = UDim2.new(0, 10, 0, 42)
	contentFrame.BackgroundTransparency = 1
	contentFrame.ClipsDescendants = true
	contentFrame.Parent = _hintFrame
	
	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 6)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Parent = contentFrame
	
	-- Add keybind entries
	for i, bind in ipairs(ESSENTIAL_KEYBINDS) do
		local entry = Instance.new("Frame")
		entry.Name = "Entry" .. i
		entry.Size = UDim2.new(1, 0, 0, 32)
		entry.BackgroundTransparency = 1
		entry.LayoutOrder = i
		entry.Parent = contentFrame
		
		-- Key button (styled like a keyboard key)
		local keyBtn = Instance.new("Frame")
		keyBtn.Name = "KeyButton"
		keyBtn.Size = UDim2.new(0, 40, 0, 28)
		keyBtn.Position = UDim2.new(0, 0, 0, 2)
		keyBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		keyBtn.BorderSizePixel = 0
		keyBtn.Parent = entry
		
		local keyCorner = Instance.new("UICorner")
		keyCorner.CornerRadius = UDim.new(0, 6)
		keyCorner.Parent = keyBtn
		
		local keyStroke = Instance.new("UIStroke")
		keyStroke.Color = Color3.fromRGB(150, 150, 150)
		keyStroke.Thickness = 2
		keyStroke.Parent = keyBtn
		
		local keyLabel = Instance.new("TextLabel")
		keyLabel.Name = "KeyLabel"
		keyLabel.Size = UDim2.new(1, 0, 1, 0)
		keyLabel.BackgroundTransparency = 1
		keyLabel.Text = bind.key
		keyLabel.Font = Enum.Font.GothamBold
		keyLabel.TextSize = 14
		keyLabel.TextColor3 = Color3.fromRGB(60, 60, 60)
		keyLabel.Parent = keyBtn
		
		-- Action label
		local actionLabel = Instance.new("TextLabel")
		actionLabel.Name = "ActionLabel"
		actionLabel.Size = UDim2.new(1, -50, 1, 0)
		actionLabel.Position = UDim2.new(0, 48, 0, 0)
		actionLabel.BackgroundTransparency = 1
		actionLabel.Text = bind.action
		actionLabel.Font = Enum.Font.Gotham
		actionLabel.TextSize = 13
		actionLabel.TextColor3 = Color3.fromRGB(80, 70, 60)
		actionLabel.TextXAlignment = Enum.TextXAlignment.Left
		actionLabel.Parent = entry
	end
	
	-- Footer tip
	local footer = Instance.new("TextLabel")
	footer.Name = "Footer"
	footer.Size = UDim2.new(1, -20, 0, 30)
	footer.Position = UDim2.new(0, 10, 1, -36)
	footer.BackgroundTransparency = 1
	footer.Text = "💡 Press F1 for all controls"
	footer.Font = Enum.Font.GothamMedium
	footer.TextSize = 11
	footer.TextColor3 = Color3.fromRGB(100, 90, 80)
	footer.TextTransparency = 0.3
	footer.TextWrapped = true
	footer.Parent = _hintFrame
	
	-- Minimize button functionality
	minimizeBtn.MouseButton1Click:Connect(function()
		_isMinimized = not _isMinimized
		
		if _isMinimized then
			-- Minimize
			minimizeBtn.Text = "+"
			TweenService:Create(_hintFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
				Size = UDim2.new(0, 240, 0, 44)
			}):Play()
			TweenService:Create(contentFrame, TweenInfo.new(0.2), {
				Size = UDim2.new(1, -20, 0, 0)
			}):Play()
			TweenService:Create(footer, TweenInfo.new(0.2), {
				TextTransparency = 1
			}):Play()
		else
			-- Expand
			minimizeBtn.Text = "−"
			TweenService:Create(_hintFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
				Size = UDim2.new(0, 240, 0, 280)
			}):Play()
			TweenService:Create(contentFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
				Size = UDim2.new(1, -20, 1, -48)
			}):Play()
			TweenService:Create(footer, TweenInfo.new(0.3), {
				TextTransparency = 0.3
			}):Play()
		end
	end)
	
	-- Fade in animation
	_hintFrame.BackgroundTransparency = 1
	for _, child in ipairs(_hintFrame:GetDescendants()) do
		if child:IsA("TextLabel") or child:IsA("TextButton") then
			child.TextTransparency = 1
		elseif child:IsA("GuiObject") then
			child.BackgroundTransparency = 1
		end
		if child:IsA("UIStroke") then
			child.Transparency = 1
		end
	end
	
	task.wait(1) -- Wait a bit before showing
	
	-- Fade in
	TweenService:Create(_hintFrame, TweenInfo.new(0.5), {
		BackgroundTransparency = 0.05
	}):Play()
	
	for _, child in ipairs(_hintFrame:GetDescendants()) do
		if child:IsA("TextLabel") and child.Name ~= "Footer" then
			TweenService:Create(child, TweenInfo.new(0.5), {
				TextTransparency = 0
			}):Play()
		elseif child:IsA("TextButton") then
			TweenService:Create(child, TweenInfo.new(0.5), {
				BackgroundTransparency = 0,
				TextTransparency = 0
			}):Play()
		elseif child:IsA("Frame") and child.Name == "KeyButton" then
			TweenService:Create(child, TweenInfo.new(0.5), {
				BackgroundTransparency = 0
			}):Play()
		end
		if child:IsA("UIStroke") then
			TweenService:Create(child, TweenInfo.new(0.5), {
				Transparency = 0.3
			}):Play()
		end
	end
	
	TweenService:Create(footer, TweenInfo.new(0.5), {
		TextTransparency = 0.3
	}):Play()
	
	print("[StartupKeybindHint] ✅ Keybind hint created and visible")
end

function StartupKeybindHint.init()
	createHintGUI()
	
	-- Auto-minimize after 30 seconds if player hasn't interacted
	task.spawn(function()
		task.wait(30)
		if not _isMinimized and _hintFrame then
			-- Programmatically minimize
			_isMinimized = true
			local minimizeBtn = _hintFrame:FindFirstChild("MinimizeBtn")
			local contentFrame = _hintFrame:FindFirstChild("ContentFrame")
			local footer = _hintFrame:FindFirstChild("Footer")
			
			if minimizeBtn then
				minimizeBtn.Text = "+"
			end
			
			if _hintFrame then
				TweenService:Create(_hintFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
					Size = UDim2.new(0, 240, 0, 44)
				}):Play()
			end
			
			if contentFrame then
				TweenService:Create(contentFrame, TweenInfo.new(0.2), {
					Size = UDim2.new(1, -20, 0, 0)
				}):Play()
			end
			
			if footer then
				TweenService:Create(footer, TweenInfo.new(0.2), {
					TextTransparency = 1
				}):Play()
			end
		end
	end)
end

function StartupKeybindHint.show()
	if _screenGui then
		_screenGui.Enabled = true
	end
end

function StartupKeybindHint.hide()
	if _screenGui then
		_screenGui.Enabled = false
	end
end

function StartupKeybindHint.destroy()
	if _screenGui then
		_screenGui:Destroy()
		_screenGui = nil
		_hintFrame = nil
	end
end

return StartupKeybindHint
