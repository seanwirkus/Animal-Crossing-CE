--[[
	ResponsiveGUI - Bulletproof responsive UI components
	Handles ANY screen size, never goes off-screen
	Works on phones, tablets, desktops, ultrawide monitors
]]

local ResponsiveGUI = {}
ResponsiveGUI.__index = ResponsiveGUI

-- Default theme
ResponsiveGUI.THEME = {
	backgroundColor = Color3.fromRGB(255, 250, 240),
	panelColor = Color3.fromRGB(255, 255, 255),
	primaryColor = Color3.fromRGB(76, 175, 80),
	secondaryColor = Color3.fromRGB(33, 150, 243),
	accentColor = Color3.fromRGB(255, 152, 0),
	textColor = Color3.fromRGB(60, 60, 60),
	lightTextColor = Color3.fromRGB(120, 120, 120),
	errorColor = Color3.fromRGB(244, 67, 54),
	successColor = Color3.fromRGB(76, 175, 80),
	borderColor = Color3.fromRGB(200, 200, 200),
}

--[[
	Create a responsive dialog that scales to screen size
	NEVER goes off screen, always centered
]]
function ResponsiveGUI.CreateDialog(parent, options)
	options = options or {}
	
	-- Main container
	local container = Instance.new("Frame")
	container.Name = options.name or "Dialog"
	container.BackgroundTransparency = 1
	container.Size = UDim2.new(1, 0, 1, 0)
	container.Parent = parent
	
	-- Backdrop
	local backdrop = Instance.new("Frame")
	backdrop.Name = "Backdrop"
	backdrop.Size = UDim2.new(1, 0, 1, 0)
	backdrop.BackgroundColor3 = Color3.new(0, 0, 0)
	backdrop.BackgroundTransparency = options.backdropTransparency or 0.3
	backdrop.BorderSizePixel = 0
	backdrop.ZIndex = 1
	backdrop.Parent = container
	
	-- Panel with constraints
	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.BackgroundColor3 = options.panelColor or ResponsiveGUI.THEME.panelColor
	panel.BorderSizePixel = 0
	panel.ZIndex = 2
	panel.Parent = container
	
	-- Add corner radius
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 20)
	corner.Parent = panel
	
	-- Add padding inside
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 24)
	padding.PaddingRight = UDim.new(0, 24)
	padding.PaddingTop = UDim.new(0, 24)
	padding.PaddingBottom = UDim.new(0, 24)
	padding.Parent = panel
	
	-- Calculate responsive size
	local function updateSize()
		local screenSize = container.AbsoluteSize
		
		-- Responsive width: 90% of screen, min 300, max 800
		local maxWidth = math.min(screenSize.X * 0.9, 800)
		local minWidth = math.min(screenSize.X * 0.9, 300)
		local width = math.max(minWidth, maxWidth)
		
		-- Responsive height: 80% of screen, min 200, max 700
		local maxHeight = math.min(screenSize.Y * 0.8, 700)
		local minHeight = math.min(screenSize.Y * 0.8, 200)
		local height = math.max(minHeight, maxHeight)
		
		-- Clamp to screen bounds with padding
		local finalWidth = math.min(width, screenSize.X - 20)
		local finalHeight = math.min(height, screenSize.Y - 20)
		
		panel.Size = UDim2.new(0, finalWidth, 0, finalHeight)
		panel.Position = UDim2.new(0.5, -finalWidth / 2, 0.5, -finalHeight / 2)
	end
	
	-- Update on resize
	container.Changed:Connect(function(prop)
		if prop == "AbsoluteSize" then
			updateSize()
		end
	end)
	
	-- Initial size
	task.defer(updateSize)
	
	return panel, container
end

--[[
	Create a responsive title
]]
function ResponsiveGUI.CreateTitle(parent, options)
	options = options or {}
	
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.TextColor3 = options.textColor or ResponsiveGUI.THEME.textColor
	title.Font = Enum.Font.GothamBold
	title.TextWrapped = true
	title.Text = options.text or "Title"
	title.Parent = parent
	
	-- Responsive text size: scale with screen
	local function updateTextSize()
		local parentSize = parent.AbsoluteSize
		-- Scale text between 20 and 36 based on screen width
		local textSize = math.max(20, math.min(36, parentSize.X / 20))
		title.TextSize = textSize
	end
	
	parent.Changed:Connect(function(prop)
		if prop == "AbsoluteSize" then
			updateTextSize()
		end
	end)
	
	-- Position and size
	title.Size = UDim2.new(1, 0, 0, 60)
	title.Position = UDim2.new(0, 0, 0, 0)
	
	task.defer(updateTextSize)
	return title
end

--[[
	Create a responsive button that fits content
]]
function ResponsiveGUI.CreateButton(parent, options)
	options = options or {}
	
	local button = Instance.new("TextButton")
	button.Name = options.name or "Button"
	button.BackgroundColor3 = options.color or ResponsiveGUI.THEME.primaryColor
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamBold
	button.TextColor3 = Color3.new(1, 1, 1)
	button.AutoButtonColor = false
	button.Text = options.text or "Button"
	button.Parent = parent
	
	-- Corner radius
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = button
	
	-- Responsive text size
	local function updateTextSize()
		local parentSize = parent.AbsoluteSize
		local textSize = math.max(12, math.min(18, parentSize.X / 30))
		button.TextSize = textSize
	end
	
	parent.Changed:Connect(function(prop)
		if prop == "AbsoluteSize" then
			updateTextSize()
		end
	end)
	
	-- Default size
	button.Size = UDim2.new(1, 0, 0, 50)
	if options.position then
		button.Position = UDim2.new(0, 0, 0, options.position)
	end
	
	-- Hover effect
	local TweenService = game:GetService("TweenService")
	button.MouseEnter:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.2), {
			BackgroundColor3 = Color3.new(
				math.min(1, button.BackgroundColor3.R + 0.1),
				math.min(1, button.BackgroundColor3.G + 0.1),
				math.min(1, button.BackgroundColor3.B + 0.1)
			)
		}):Play()
	end)
	
	button.MouseLeave:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.2), {
			BackgroundColor3 = options.color or ResponsiveGUI.THEME.primaryColor
		}):Play()
	end)
	
	-- Click callback
	if options.callback then
		button.MouseButton1Click:Connect(options.callback)
	end
	
	task.defer(updateTextSize)
	return button
end

--[[
	Create a responsive text input
]]
function ResponsiveGUI.CreateTextInput(parent, options)
	options = options or {}
	
	local input = Instance.new("TextBox")
	input.Name = options.name or "TextInput"
	input.BackgroundColor3 = Color3.fromRGB(245, 245, 245)
	input.BorderColor3 = ResponsiveGUI.THEME.borderColor
	input.BorderSizePixel = 1
	input.Font = Enum.Font.Gotham
	input.TextColor3 = ResponsiveGUI.THEME.textColor
	input.PlaceholderColor3 = ResponsiveGUI.THEME.lightTextColor
	input.PlaceholderText = options.placeholder or "Enter text..."
	input.Parent = parent
	
	-- Corner radius
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = input
	
	-- Padding
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 12)
	padding.PaddingRight = UDim.new(0, 12)
	padding.Parent = input
	
	-- Responsive text size
	local function updateTextSize()
		local parentSize = parent.AbsoluteSize
		local textSize = math.max(12, math.min(16, parentSize.X / 40))
		input.TextSize = textSize
	end
	
	parent.Changed:Connect(function(prop)
		if prop == "AbsoluteSize" then
			updateTextSize()
		end
	end)
	
	-- Default size
	input.Size = UDim2.new(1, 0, 0, 44)
	if options.position then
		input.Position = UDim2.new(0, 0, 0, options.position)
	end
	
	task.defer(updateTextSize)
	return input
end

--[[
	Create a responsive scrolling list
]]
function ResponsiveGUI.CreateScrollList(parent, options)
	options = options or {}
	
	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Name = "ScrollList"
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.BorderSizePixel = 0
	scrollFrame.ScrollBarThickness = 8
	scrollFrame.ScrollBarImageColor3 = ResponsiveGUI.THEME.primaryColor
	scrollFrame.Parent = parent
	
	-- List layout
	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 12)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.FillDirection = Enum.FillDirection.Vertical
	listLayout.Parent = scrollFrame
	
	-- Size and position
	scrollFrame.Size = UDim2.new(1, 0, 1, -80)
	scrollFrame.Position = UDim2.new(0, 0, 0, 80)
	
	-- Update canvas size when children change
	local function updateCanvasSize()
		task.wait(0.1)
		scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 20)
	end
	
	listLayout.Changed:Connect(updateCanvasSize)
	parent.ChildAdded:Connect(updateCanvasSize)
	
	return scrollFrame
end

--[[
	Create a responsive grid for cards
]]
function ResponsiveGUI.CreateCardGrid(parent, options)
	options = options or {}
	local columnCount = options.columns or 2
	
	local container = Instance.new("Frame")
	container.Name = "CardGrid"
	container.BackgroundTransparency = 1
	container.BorderSizePixel = 0
	container.Size = UDim2.new(1, 0, 1, 0)
	container.Parent = parent
	
	-- Grid layout
	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	gridLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	gridLayout.Parent = container
	
	-- Responsive grid sizing
	local function updateGridSize()
		local parentSize = container.AbsoluteSize
		local padding = 15
		local availableWidth = parentSize.X - (padding * (columnCount + 1))
		local cardWidth = availableWidth / columnCount
		local cardHeight = cardWidth * 0.75  -- 4:3 ratio
		
		gridLayout.CellSize = UDim2.new(0, math.max(150, cardWidth), 0, math.max(112, cardHeight))
		gridLayout.CellPadding = UDim2.new(0, padding, 0, padding)
	end
	
	container.Changed:Connect(function(prop)
		if prop == "AbsoluteSize" then
			updateGridSize()
		end
	end)
	
	task.defer(updateGridSize)
	return container
end

--[[
	Create a responsive card for grid
]]
function ResponsiveGUI.CreateCard(parent, options)
	options = options or {}
	
	local card = Instance.new("Frame")
	card.Name = options.name or "Card"
	card.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	card.BorderColor3 = ResponsiveGUI.THEME.borderColor
	card.BorderSizePixel = 1
	card.LayoutOrder = options.order or 1
	card.Parent = parent
	
	-- Corner radius
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = card
	
	-- Padding
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 12)
	padding.PaddingRight = UDim.new(0, 12)
	padding.PaddingTop = UDim.new(0, 12)
	padding.PaddingBottom = UDim.new(0, 12)
	padding.Parent = card
	
	-- Title
	if options.title then
		local title = Instance.new("TextLabel")
		title.Name = "Title"
		title.Size = UDim2.new(1, 0, 0, 30)
		title.BackgroundTransparency = 1
		title.Text = options.title
		title.TextColor3 = ResponsiveGUI.THEME.textColor
		title.Font = Enum.Font.GothamBold
		title.TextSize = 16
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.Parent = card
	end
	
	-- Hover effect
	local TweenService = game:GetService("TweenService")
	card.MouseEnter:Connect(function()
		TweenService:Create(card, TweenInfo.new(0.15), {
			BackgroundColor3 = Color3.fromRGB(248, 248, 248),
			BorderColor3 = ResponsiveGUI.THEME.primaryColor
		}):Play()
	end)
	
	card.MouseLeave:Connect(function()
		TweenService:Create(card, TweenInfo.new(0.15), {
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BorderColor3 = ResponsiveGUI.THEME.borderColor
		}):Play()
	end)
	
	return card
end

--[[
	Create a compact icon button with tooltip
	Perfect for toolbars and compact UIs
]]
function ResponsiveGUI.CreateIconButton(parent, options)
	options = options or {}
	
	local container = Instance.new("Frame")
	container.Name = options.name or "IconButton"
	container.BackgroundTransparency = 1
	container.Size = UDim2.new(0, 80, 0, 80)
	container.LayoutOrder = options.order or 1
	container.Parent = parent
	
	-- Button
	local button = Instance.new("TextButton")
	button.Name = "Button"
	button.Size = UDim2.new(1, 0, 1, 0)
	button.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	button.BorderSizePixel = 1
	button.BorderColor3 = ResponsiveGUI.THEME.borderColor
	button.AutoButtonColor = false
	button.Text = ""
	button.Parent = container
	
	-- Rounded corners
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = button
	
	-- Icon
	local icon = Instance.new("TextLabel")
	icon.Name = "Icon"
	icon.Size = UDim2.new(1, 0, 0, 40)
	icon.Position = UDim2.new(0, 0, 0, 10)
	icon.BackgroundTransparency = 1
	icon.Text = options.icon or "📦"
	icon.TextSize = 28
	icon.Font = Enum.Font.GothamBold
	icon.Parent = button
	
	-- Label
	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.new(1, -8, 0, 22)
	label.Position = UDim2.new(0, 4, 1, -28)
	label.BackgroundTransparency = 1
	label.Text = options.text or "Button"
	label.TextSize = 11
	label.Font = Enum.Font.Gotham
	label.TextColor3 = ResponsiveGUI.THEME.textColor
	label.TextWrapped = true
	label.TextScaled = true
	label.Parent = button
	
	-- Cost badge (optional)
	if options.cost then
		local costBadge = Instance.new("Frame")
		costBadge.Name = "CostBadge"
		costBadge.Size = UDim2.new(0, 50, 0, 18)
		costBadge.Position = UDim2.new(0.5, -25, 0, 52)
		costBadge.BackgroundColor3 = options.cost > 0 and ResponsiveGUI.THEME.primaryColor or ResponsiveGUI.THEME.successColor
		costBadge.BorderSizePixel = 0
		costBadge.Parent = button
		
		local costCorner = Instance.new("UICorner")
		costCorner.CornerRadius = UDim.new(0, 6)
		costCorner.Parent = costBadge
		
		local costText = Instance.new("TextLabel")
		costText.Size = UDim2.new(1, 0, 1, 0)
		costText.BackgroundTransparency = 1
		costText.Text = options.cost > 0 and tostring(options.cost) or "FREE"
		costText.TextSize = 10
		costText.Font = Enum.Font.GothamBold
		costText.TextColor3 = Color3.new(1, 1, 1)
		costText.Parent = costBadge
	end
	
	-- Hover effect
	local TweenService = game:GetService("TweenService")
	button.MouseEnter:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.15), {
			BackgroundColor3 = Color3.fromRGB(245, 250, 245),
			BorderColor3 = ResponsiveGUI.THEME.primaryColor,
			Size = UDim2.new(1.05, 0, 1.05, 0)
		}):Play()
		TweenService:Create(icon, TweenInfo.new(0.15), {
			TextSize = 32
		}):Play()
	end)
	
	button.MouseLeave:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.15), {
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BorderColor3 = ResponsiveGUI.THEME.borderColor,
			Size = UDim2.new(1, 0, 1, 0)
		}):Play()
		TweenService:Create(icon, TweenInfo.new(0.15), {
			TextSize = 28
		}):Play()
	end)
	
	-- Click callback
	if options.callback then
		button.MouseButton1Click:Connect(options.callback)
	end
	
	return container
end

--[[
	Constraint helper - prevents GUI from going off screen
]]
function ResponsiveGUI.ConstrainToScreen(frame, options)
	options = options or {}
	local minPadding = options.minPadding or 10
	
	local function constrain()
		local parent = frame.Parent
		if not parent then return end
		
		local screenSize = parent.AbsoluteSize
		local frameSize = frame.AbsoluteSize
		
		-- Calculate max position to keep on screen
		local maxX = screenSize.X - frameSize.X - minPadding
		local maxY = screenSize.Y - frameSize.Y - minPadding
		
		-- Get current position
		local pos = frame.Position
		local offsetX = pos.Offset.X
		local offsetY = pos.Offset.Y
		
		-- Constrain to bounds
		offsetX = math.max(minPadding, math.min(offsetX, maxX))
		offsetY = math.max(minPadding, math.min(offsetY, maxY))
		
		frame.Position = UDim2.new(pos.Scale.X, offsetX, pos.Scale.Y, offsetY)
	end
	
	frame.Parent.Changed:Connect(function(prop)
		if prop == "AbsoluteSize" then
			constrain()
		end
	end)
	
	frame.Changed:Connect(function(prop)
		if prop == "Size" or prop == "AbsoluteSize" then
			constrain()
		end
	end)
	
	task.defer(constrain)
end

return ResponsiveGUI
