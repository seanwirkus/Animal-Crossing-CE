--[[
	Components - Recreated from RBXMX Assets as Pure Luau
	
	This module provides reusable UI components that were originally
	designed in Figma and exported to RBXMX. Now recreated as code.
	
	Components:
	- CreateButton: AC-styled button with icon and text
	- CreateBellsDisplay: Money/currency display widget
	- CreateToolIcon: Tool icon display
	- CreateDialogueBox: Dialogue/chat box template
]]

local TweenService = game:GetService("TweenService")

local Components = {}

-- ============================================================
-- BUTTON COMPONENT
-- ============================================================
--[[
	Creates an AC-styled button with icon and text
	Original: [A] Button.rbxmx
]]
function Components.CreateButton(parent, text, iconImage, size, position)
	size = size or UDim2.new(0, 170, 0, 66)
	position = position or UDim2.new(0, 0, 0, 0)
	
	-- Main background
	local background = Instance.new("Frame")
	background.Name = "Button"
	background.BackgroundColor3 = Color3.fromRGB(247, 248, 230)  -- Beige
	background.BackgroundTransparency = 0
	background.BorderSizePixel = 0
	background.Size = size
	background.Position = position
	background.Active = true
	background.Parent = parent
	
	-- Rounded corners
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 32)
	corner.Parent = background
	
	-- Inner container (with padding)
	local container = Instance.new("Frame")
	container.Name = "Container"
	container.BackgroundTransparency = 1
	container.BorderSizePixel = 0
	container.Size = UDim2.new(1, -26, 1, -14)
	container.Position = UDim2.new(0, 13, 0, 7)
	container.Parent = background
	
	-- Icon button
	local iconButton = Instance.new("ImageButton")
	iconButton.Name = "Icon"
	iconButton.BackgroundTransparency = 1
	iconButton.BorderSizePixel = 0
	iconButton.Size = UDim2.new(0, 46, 0, 46)
	iconButton.Position = UDim2.new(0, 0, 0.5, -23)
	iconButton.Image = iconImage or ""
	iconButton.ImageColor3 = Color3.fromRGB(138, 123, 102)  -- Brown
	iconButton.ImageTransparency = 0
	iconButton.ZIndex = 2
	iconButton.Parent = container
	
	-- Text label
	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "Text"
	textLabel.BackgroundTransparency = 1
	textLabel.BorderSizePixel = 0
	textLabel.Size = UDim2.new(0, 86, 0, 52)
	textLabel.Position = UDim2.new(0, 58, 0, 0)
	textLabel.Text = text or "Text"
	textLabel.TextSize = 16
	textLabel.TextColor3 = Color3.fromRGB(138, 123, 102)  -- Brown
	textLabel.Font = Enum.Font.GothamBold
	textLabel.TextWrapped = true
	textLabel.ZIndex = 2
	textLabel.Parent = container
	
	-- Hover effect
	local hoverTween = nil
	background.MouseEnter:Connect(function()
		if hoverTween then hoverTween:Cancel() end
		hoverTween = TweenService:Create(background, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundColor3 = Color3.fromRGB(230, 235, 210)
		})
		hoverTween:Play()
	end)
	
	background.MouseLeave:Connect(function()
		if hoverTween then hoverTween:Cancel() end
		hoverTween = TweenService:Create(background, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundColor3 = Color3.fromRGB(247, 248, 230)
		})
		hoverTween:Play()
	end)
	
        return background, iconButton, textLabel
end

-- ============================================================
-- BELLS DISPLAY COMPONENT (New Tailwind Design)
-- ============================================================
--[[
	Creates a currency display widget
	Translated from Tailwind React:
	- Cream outer ring (#fffbe7)
	- Golden inner pill (#bea745)
	- White text, centered
	- Fully rounded (57.48px radius)
]]
function Components.CreateBellsDisplay(parent, amount, position)
	amount = amount or 0
	position = position or UDim2.new(0, 0, 0, 0)
	
	-- Outer frame (cream ring with padding)
	local outerFrame = Instance.new("Frame")
	outerFrame.Name = "BellsDisplay"
	outerFrame.BackgroundColor3 = Color3.fromRGB(255, 251, 231) -- #fffbe7
	outerFrame.BackgroundTransparency = 0
	outerFrame.BorderSizePixel = 0
	outerFrame.Size = UDim2.new(0, 200, 0, 60) -- Adjusted height to ~117px aspect
	outerFrame.Position = position
	outerFrame.Parent = parent
	
	-- Fully rounded corners (57.48px ~ 58)
	local outerCorner = Instance.new("UICorner")
	outerCorner.CornerRadius = UDim.new(0, 58)
	outerCorner.Parent = outerFrame
	
	-- Padding (6px equivalent, Tailwind p-1.5)
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 6)
	padding.PaddingRight = UDim.new(0, 6)
	padding.PaddingTop = UDim.new(0, 6)
	padding.PaddingBottom = UDim.new(0, 6)
	padding.Parent = outerFrame
	
	-- Inner frame (golden pill background)
	local innerFrame = Instance.new("Frame")
	innerFrame.Name = "InnerPill"
	innerFrame.BackgroundColor3 = Color3.fromRGB(190, 167, 69) -- #bea745
	innerFrame.BackgroundTransparency = 0
	innerFrame.BorderSizePixel = 0
	innerFrame.Size = UDim2.new(1, 0, 1, 0) -- Fill parent minus padding
	innerFrame.Position = UDim2.new(0, 0, 0, 0)
	innerFrame.Parent = outerFrame
	
	-- Fully rounded corners (match outer)
	local innerCorner = Instance.new("UICorner")
	innerCorner.CornerRadius = UDim.new(0, 52)
	innerCorner.Parent = innerFrame
	
	-- Inner padding (50px horizontal from Tailwind px-[50px])
	local innerPadding = Instance.new("UIPadding")
	innerPadding.PaddingLeft = UDim.new(0, 20)
	innerPadding.PaddingRight = UDim.new(0, 20)
	innerPadding.PaddingTop = UDim.new(0, 8)
	innerPadding.PaddingBottom = UDim.new(0, 8)
	innerPadding.Parent = innerFrame
	
	-- Amount text (white, centered, Roboto-Medium, 54px)
	local amountText = Instance.new("TextLabel")
	amountText.Name = "Amount"
	amountText.BackgroundTransparency = 1
	amountText.BorderSizePixel = 0
	amountText.Size = UDim2.new(1, 0, 1, 0)
	amountText.Text = tostring(amount)
	amountText.TextSize = 28 -- Scaled down from 54px to fit Roblox
	amountText.TextColor3 = Color3.fromRGB(255, 255, 255) -- Off-white
	amountText.Font = Enum.Font.GothamMedium
	amountText.TextXAlignment = Enum.TextXAlignment.Center
	amountText.TextYAlignment = Enum.TextYAlignment.Center
	amountText.TextScaled = true
	amountText.Parent = innerFrame
	
	-- Constrain text size
	local textSizeConstraint = Instance.new("UITextSizeConstraint")
	textSizeConstraint.MaxTextSize = 32
	textSizeConstraint.Parent = amountText
	
	return outerFrame, amountText
end

-- ============================================================
-- TOOL ICON COMPONENT
-- ============================================================
--[[
	Creates a tool icon display frame
	Original: shovel-icon.rbxmx
]]
function Components.CreateToolIcon(parent, position)
	position = position or UDim2.new(0, 0, 0, 0)
	
	-- Main frame
	local frame = Instance.new("Frame")
	frame.Name = "ToolIcon"
	frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	frame.BackgroundTransparency = 0
	frame.BorderSizePixel = 0
	frame.Size = UDim2.new(0, 80, 0, 80)
	frame.Position = position
	frame.Parent = parent
	
	-- Corner radius
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = frame
	
	-- Icon placeholder
	local icon = Instance.new("TextLabel")
	icon.Name = "Icon"
	icon.BackgroundTransparency = 1
	icon.BorderSizePixel = 0
	icon.Size = UDim2.new(1, 0, 1, 0)
	icon.Text = "🪓"
	icon.TextSize = 40
	icon.Font = Enum.Font.GothamBold
	icon.Parent = frame
	
        return frame, icon
end

-- ============================================================
-- DIALOGUE BOX COMPONENT
-- ============================================================
--[[
	Creates a dialogue box for NPC conversations
	Original: dialogue-box_empty.rbxmx
]]
function Components.CreateDialogueBox(parent, dialogueText, position)
	dialogueText = dialogueText or "Hello!"
	position = position or UDim2.new(0, 0, 0, 0)
	
	-- Main frame
	local frame = Instance.new("Frame")
	frame.Name = "DialogueBox"
	frame.BackgroundColor3 = Color3.fromRGB(240, 235, 225)
	frame.BackgroundTransparency = 0
	frame.BorderSizePixel = 0
	frame.Size = UDim2.new(0, 400, 0, 120)
	frame.Position = position
	frame.Parent = parent
	
	-- Corner radius
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = frame
	
	-- Padding
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 15)
	padding.PaddingRight = UDim.new(0, 15)
	padding.PaddingTop = UDim.new(0, 10)
	padding.PaddingBottom = UDim.new(0, 10)
	padding.Parent = frame
	
	-- Dialogue text
	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "Text"
	textLabel.BackgroundTransparency = 1
	textLabel.BorderSizePixel = 0
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.Text = dialogueText
	textLabel.TextSize = 16
	textLabel.TextColor3 = Color3.fromRGB(60, 40, 20)
	textLabel.Font = Enum.Font.Gotham
	textLabel.TextWrapped = true
	textLabel.TextXAlignment = Enum.TextXAlignment.Left
	textLabel.TextYAlignment = Enum.TextYAlignment.Top
	textLabel.Parent = frame
	
        return frame, textLabel
end

return Components
